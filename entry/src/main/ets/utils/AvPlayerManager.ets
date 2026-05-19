import { media } from '@kit.MediaKit'
import { GlobalMusic } from '../models/globalMusic'
import { SongItemType } from '../models/music'
import { AppStorageV2 } from '@kit.ArkUI'
import { sessionManager } from './AvSessionManager'
import { avSession } from '@kit.AVSessionKit'

class AvPlayerManager {
  // 1. 播放器实例
  player: media.AVPlayer | null = null
  // 2. 共享播放数据 (全局唯一状态)
  currentSong: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!

  // ===================== 生命周期与初始化 =====================

  // 创建播放器 + 监听播放器的状态
  async init () {
    if (!this.player) {
      this.player = await media.createAVPlayer()
    }

    // 监听状态机流转
    this.player.on('stateChange', (state) => {
      if (state === 'initialized') {
        this.player?.prepare()
      } else if (state === 'prepared') {
        this.player?.play()
        this.currentSong.isPlay = true
        // 【联动】：准备好开始播放时，通知系统“播放”状态，并带上当前进度
        sessionManager.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PLAY, this.currentSong.time)
      } else if (state === 'completed') {
        this.autoPlayNext()
      }
    })

    // 监听总时长变化
    this.player.on('durationUpdate',(duration) =>{
      this.currentSong.duration = duration
      // 【联动】：拿到真实的歌曲时长后，立刻同步给系统，此时通知栏会跳出进度条
      const song = this.currentSong.playList[this.currentSong.playIndex]
      if (song) {
        sessionManager.setMetadata(song, duration)
      }
    })

    // 监听播放进度变化
    this.player.on('timeUpdate',(time) =>{
      this.currentSong.time = time
    })
  }

  // ===================== 基础播放控制 =====================

  // 播放指定歌曲
  singPlay (song: SongItemType){
    // 【联动系统后台】：确保长时任务开启，防止锁屏杀后台
    sessionManager.startBackgroundTask(getContext())

    const inList = this.currentSong.playList.some(item => item.id === song.id)
    if (inList) {
      if (this.currentSong.url === song.url) {
        this.player?.play()
        this.currentSong.isPlay = true
        // 继续播放时，通知系统状态
        sessionManager.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PLAY, this.currentSong.time)
      } else {
        this.currentSong.playIndex = this.currentSong.playList.findIndex(item => item.id === song.id)
        this.changeSong()
      }
    } else {
      this.currentSong.playList.unshift(song)
      this.currentSong.playIndex = 0
      this.changeSong()
    }
  }

  // 核心切歌逻辑
  async changeSong() {
    if (!this.player) return

    await this.player.reset()
    this.currentSong.duration = 0
    this.currentSong.time = 0

    const song = this.currentSong.playList[this.currentSong.playIndex]
    this.currentSong.img = song.img
    this.currentSong.name = song.name
    this.currentSong.author = song.author
    this.currentSong.url = song.url

    // 【联动】：切歌刚开始还没获取到时长，传入0，让系统先刷新封面和歌名
    sessionManager.setMetadata(song, 0)

    this.player.url = this.currentSong.url
  }

  // 拖拽进度条跳转
  seekPlay(value: number) {
    this.player?.seek(value)
    // 【联动】：在APP里拖拽进度条后，通知系统同步进度
    const state = this.currentSong.isPlay ? avSession.PlaybackState.PLAYBACK_STATE_PLAY : avSession.PlaybackState.PLAYBACK_STATE_PAUSE
    sessionManager.setPlaybackState(state, value)
  }

  // 暂停播放
  paused () {
    this.player?.pause()
    this.currentSong.isPlay = false
    // 【联动】：暂停时，通知系统暂停图标，并传入当前停留在几秒
    sessionManager.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PAUSE, this.currentSong.time)
  }

  // ===================== 播放模式控制逻辑 =====================

  // 歌曲自然播放结束时触发的逻辑
  autoPlayNext() {
    const mode = this.currentSong.playMode
    const listLen = this.currentSong.playList.length
    if (listLen === 0) return

    if (mode === 'repeat') {
      this.changeSong()
    } else if (mode === 'random') {
      this.setRandomIndex(listLen)
      this.changeSong()
    } else {
      this.currentSong.playIndex++
      if (this.currentSong.playIndex >= listLen) {
        this.currentSong.playIndex = 0
      }
      this.changeSong()
    }
  }

  // 用户点击“上一首”
  prevPlay() {
    const mode = this.currentSong.playMode
    const listLen = this.currentSong.playList.length
    if (listLen === 0) return

    if (mode === 'random') {
      this.setRandomIndex(listLen)
    } else {
      this.currentSong.playIndex--
      if (this.currentSong.playIndex < 0) {
        this.currentSong.playIndex = listLen - 1
      }
    }
    this.changeSong()
  }

  // 用户点击“下一首”
  nextPlay() {
    const mode = this.currentSong.playMode
    const listLen = this.currentSong.playList.length
    if (listLen === 0) return

    if (mode === 'random') {
      this.setRandomIndex(listLen)
    } else {
      this.currentSong.playIndex++
      if (this.currentSong.playIndex >= listLen) {
        this.currentSong.playIndex = 0
      }
    }
    this.changeSong()
  }

  // 私有辅助方法：生成不会与当前重复的随机索引
  private setRandomIndex(listLen: number) {
    if (listLen <= 1) return
    let randomIndex = Math.floor(Math.random() * listLen)
    if (randomIndex === this.currentSong.playIndex) {
      randomIndex = (randomIndex + 1) % listLen
    }
    this.currentSong.playIndex = randomIndex
  }

  // ===================== 播放列表管理 =====================

  // 滑动删除播放列表中的歌曲
  removeSong(index: number) {
    const list = this.currentSong.playList
    if (list.length === 0) return

    // 情况1：如果列表只剩最后1首歌，并且把它删了
    if (list.length === 1) {
      this.player?.reset()
      list.splice(0, 1)
      this.currentSong.playIndex = 0
      this.currentSong.isPlay = false
      this.currentSong.time = 0
      this.currentSong.duration = 0
      this.currentSong.name = '暂无歌曲'
      this.currentSong.author = ''
      sessionManager.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PAUSE, 0)
      return
    }

    // 情况2：如果删除的是【当前正在播放的这首歌】
    if (index === this.currentSong.playIndex) {
      list.splice(index, 1)
      if (this.currentSong.playIndex >= list.length) {
        this.currentSong.playIndex = 0
      }
      this.changeSong()
    }
    // 情况3：如果删除的是【正在播放的歌曲前面的歌】
    else if (index < this.currentSong.playIndex) {
      list.splice(index, 1)
      this.currentSong.playIndex--
    }
    // 情况4：如果删除的是后面的歌，不影响当前播放，直接删
    else {
      list.splice(index, 1)
    }
  }
}

// 导出全局单例
export const playerManager: AvPlayerManager = new AvPlayerManager()