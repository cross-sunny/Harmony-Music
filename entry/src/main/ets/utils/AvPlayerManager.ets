import { media } from '@kit.MediaKit'
import { GlobalMusic } from '../models/globalMusic'
import { SongItemType } from '../models/music'
import { AppStorageV2 } from '@kit.ArkUI'
import { sessionManager } from './AvSessionManager'
import { avSession } from '@kit.AVSessionKit'

const TAG = '[Music_Player]'

class AvPlayerManager {
  player: media.AVPlayer | null = null
  currentSong: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!

  async init () {
    if (!this.player) {
      this.player = await media.createAVPlayer()
    }

    this.player.on('stateChange', (state) => {
      switch (state) {
        case 'initialized':
          this.player?.prepare()
          break;
        case 'prepared':
          this.player?.play()
          this.currentSong.isPlay = true
          sessionManager.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PLAY)
          break;
        case 'completed':
          this.autoPlayNext()
          break;
      }
    })

    this.player.on('durationUpdate',(duration) =>{
      this.currentSong.duration = duration
      const song = this.currentSong.playList[this.currentSong.playIndex]
      if (song) sessionManager.setMetadata(song, duration)
    })

    this.player.on('timeUpdate',(time) =>{
      this.currentSong.time = time
    })
  }

  singPlay (song: SongItemType){
    sessionManager.startBackgroundTask(getContext())

    const inList = this.currentSong.playList.some(item => item.id === song.id)
    if (inList) {
      if (this.currentSong.url === song.url) {
        this.resumePlay()
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

    sessionManager.setMetadata(song, 0)
    this.player.url = this.currentSong.url
  }

  // 【终极修复】：安全的恢复播放
  resumePlay() {
    this.currentSong.isPlay = true
    // 防御性调用：只有不在 playing 状态时，才去触发播放，避免底层报错
    if (this.player?.state !== 'playing') {
      this.player?.play()
    }
    sessionManager.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PLAY)
  }

  // 【终极修复】：安全的暂停
  paused () {
    this.currentSong.isPlay = false
    // 先同步 UI 给控制中心
    sessionManager.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PAUSE)

    // 防御性调用：只有不在 paused 状态时，才去触发暂停，消灭 invalid operation 报错！
    if (this.player?.state === 'playing') {
      this.player?.pause()
    }
  }

  seekPlay(value: number) {
    this.player?.seek(value)
    const state = this.currentSong.isPlay ? avSession.PlaybackState.PLAYBACK_STATE_PLAY : avSession.PlaybackState.PLAYBACK_STATE_PAUSE
    sessionManager.setPlaybackState(state)
  }

  autoPlayNext() {
    const mode = this.currentSong.playMode
    const listLen = this.currentSong.playList.length
    if (listLen === 0) return
    if (mode === 'repeat') this.changeSong()
    else if (mode === 'random') { this.setRandomIndex(listLen); this.changeSong() }
    else {
      this.currentSong.playIndex++
      if (this.currentSong.playIndex >= listLen) this.currentSong.playIndex = 0
      this.changeSong()
    }
  }

  prevPlay() {
    const mode = this.currentSong.playMode
    const listLen = this.currentSong.playList.length
    if (listLen === 0) return
    if (mode === 'random') this.setRandomIndex(listLen)
    else {
      this.currentSong.playIndex--
      if (this.currentSong.playIndex < 0) this.currentSong.playIndex = listLen - 1
    }
    this.changeSong()
  }

  nextPlay() {
    const mode = this.currentSong.playMode
    const listLen = this.currentSong.playList.length
    if (listLen === 0) return
    if (mode === 'random') this.setRandomIndex(listLen)
    else {
      this.currentSong.playIndex++
      if (this.currentSong.playIndex >= listLen) this.currentSong.playIndex = 0
    }
    this.changeSong()
  }

  private setRandomIndex(listLen: number) {
    if (listLen <= 1) return
    let randomIndex = Math.floor(Math.random() * listLen)
    if (randomIndex === this.currentSong.playIndex) randomIndex = (randomIndex + 1) % listLen
    this.currentSong.playIndex = randomIndex
  }

  removeSong(index: number) {
    const list = this.currentSong.playList
    if (list.length === 0) return
    if (list.length === 1) {
      this.player?.reset()
      list.splice(0, 1)
      this.currentSong.playIndex = 0
      this.currentSong.isPlay = false
      this.currentSong.time = 0
      this.currentSong.duration = 0
      this.currentSong.name = '暂无歌曲'
      this.currentSong.author = ''
      sessionManager.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PAUSE)
      return
    }
    if (index === this.currentSong.playIndex) {
      list.splice(index, 1)
      if (this.currentSong.playIndex >= list.length) this.currentSong.playIndex = 0
      this.changeSong()
    } else if (index < this.currentSong.playIndex) {
      list.splice(index, 1)
      this.currentSong.playIndex--
    } else {
      list.splice(index, 1)
    }
  }
}

export const playerManager: AvPlayerManager = new AvPlayerManager()