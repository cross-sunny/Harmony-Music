import { avSession } from '@kit.AVSessionKit'
import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import { wantAgent } from '@kit.AbilityKit';
import { playerManager } from './AvPlayerManager';
import { SongItemType } from '../models/music';

class AvSessionManager {
  session: avSession.AVSession | null = null

  // 1. 初始化
  async init(context: Context) {
    // 创建会话
    this.session = await avSession.createAVSession(context, 'bgPlay', 'audio')

    // 【关键修复 1】：必须主动激活会话，否则控制中心的点击事件可能无法回调
    await this.session.activate()

    // 初始化完成后，立刻注册控制中心的监听事件
    this.registerListener()
  }

  // 2. 申请长时任务
  async startBackgroundTask (context: Context) {
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          // ⚠️注意：确保这里是你真实的 bundleName (在 AppScope/app.json5 中查看)
          bundleName: 'com.example.mylab1',
          abilityName: 'EntryAbility'
        }
      ],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    const want = await wantAgent.getWantAgent(wantAgentInfo)
    backgroundTaskManager.startBackgroundRunning(context, backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK, want)
  }

  // 3. 设置元数据 (把 duration 传进来)
  async setMetadata(song: SongItemType, duration: number = 0) {
    let metadata: avSession.AVMetadata = {
      assetId: song.id,
      title: song.name,
      artist: song.author,
      mediaImage: song.img,
      // 【核心修复1】：必须给系统传总时长，通知栏才会显示进度条！
      duration: duration
    }
    await this.session?.setAVMetadata(metadata)
  }

  // 4. 设置播放状态 (把当前进度 position 传进来)
  async setPlaybackState(state: avSession.PlaybackState, position: number = 0) {
    await this.session?.setAVPlaybackState({
      state: state,
      // 【核心修复2】：告诉系统当前播到哪了，以及当前系统时间戳
      position: {
        elapsedTime: position, // 当前播放毫秒数
        updateTime: new Date().getTime() // 必须传当前真实时间戳，系统拿到后会自动让进度条往前走，不需要我们每秒去刷新
      },
      // 播放时速度为1，暂停为0
      speed: state === avSession.PlaybackState.PLAYBACK_STATE_PLAY ? 1.0 : 0
    })
  }

  // 5. 注册控制命令 (当用户在下拉控制中心点击上一首/下一首/暂停时触发)
  registerListener() {
    if (!this.session) return

    // 【关键修复 2】：监听“播放”指令
    this.session.on('play', () => {
      // 当在控制中心点击播放时，触发播放器的 play，并更新 UI 状态
      playerManager.player?.play()
      playerManager.currentSong.isPlay = true
      this.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PLAY)
    })

    // 监听“暂停”指令
    this.session.on('pause', () => {
      // 调用封装好的暂停方法
      playerManager.paused()
    })

    // 监听“上一首”指令
    this.session.on('playPrevious', () => {
      playerManager.prevPlay()
    })

    // 监听“下一首”指令
    this.session.on('playNext', () => {
      playerManager.nextPlay()
    })

    // 监听“进度条拖拽”指令（部分设备的控制中心支持拖拽进度）
    this.session.on('seek', (time: number) => {
      playerManager.seekPlay(time)
    })
  }

  // 6. 销毁回收 (应用退出时调用)
  async destroy(context: Context) {
    // 停用并注销音频会话
    if (this.session) {
      await this.session.deactivate()
      await this.session.destroy()
    }
    // 关闭长时任务
    backgroundTaskManager.stopBackgroundRunning(context)
  }
}

export const sessionManager: AvSessionManager = new AvSessionManager()