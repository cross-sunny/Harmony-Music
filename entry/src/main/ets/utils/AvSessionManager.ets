import { avSession } from '@kit.AVSessionKit'
import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import { wantAgent } from '@kit.AbilityKit';
import { playerManager } from './AvPlayerManager';
import { SongItemType } from '../models/music';

const TAG = '[Music_Session]'

class AvSessionManager {
  session: avSession.AVSession | null = null

  async init(context: Context) {
    this.session = await avSession.createAVSession(context, 'bgPlay', 'audio')
    await this.session.activate()
    this.registerListener()
  }

  async startBackgroundTask (context: Context) {
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [{ bundleName: 'com.example.mylab1', abilityName: 'EntryAbility' }],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    const want = await wantAgent.getWantAgent(wantAgentInfo)
    backgroundTaskManager.startBackgroundRunning(context, backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK, want)
  }

  async setMetadata(song: SongItemType, duration: number = 0) {
    try {
      let metadata: avSession.AVMetadata = {
        assetId: song.id,
        title: song.name,
        artist: song.author,
        mediaImage: song.img,
        duration: duration || 0
      }
      await this.session?.setAVMetadata(metadata)
    } catch (err) {
      console.error(`${TAG} setMetadata 报错: ` + JSON.stringify(err))
    }
  }

  // 【终极修复】：去掉了所有多余参数，告别 401 报错！
  async setPlaybackState(state: avSession.PlaybackState) {
    try {
      let playbackState: avSession.AVPlaybackState = { state: state }
      // 只有在播放状态才传 speed，暂停时什么也不传
      if (state === avSession.PlaybackState.PLAYBACK_STATE_PLAY) {
        playbackState.speed = 1.0
      }
      await this.session?.setAVPlaybackState(playbackState)
      console.info(`${TAG} UI状态同步成功: State=${state}`)
    } catch (err) {
      console.error(`${TAG} setPlaybackState 报错: ` + JSON.stringify(err))
    }
  }

  registerListener() {
    if (!this.session) return

    this.session.on('play', () => {
      console.info(`${TAG} 收到 PLAY(播放) 指令`)
      playerManager.resumePlay()
    })

    this.session.on('pause', () => {
      console.info(`${TAG} 收到 PAUSE(暂停) 指令`)
      playerManager.paused()
    })

    this.session.on('playPrevious', () => { playerManager.prevPlay() })
    this.session.on('playNext', () => { playerManager.nextPlay() })
    this.session.on('seek', (time: number) => { playerManager.seekPlay(time) })
  }

  async destroy(context: Context) {
    if (this.session) {
      await this.session.deactivate()
      await this.session.destroy()
    }
    backgroundTaskManager.stopBackgroundRunning(context)
  }
}

export const sessionManager: AvSessionManager = new AvSessionManager()