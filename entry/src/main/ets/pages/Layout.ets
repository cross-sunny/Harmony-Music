import { Recommend } from "./Recommend";
import { Find } from "./Find";
import { Moment } from "./Moment";
import { Mine } from "./Mine";

interface TabClass {
  text: string
  icon: ResourceStr
}

@Builder
export function LayoutBuilder() {
  Layout()
}

@Preview
@ComponentV2
struct Layout {
  @Local index: number = 0;
  pathStack: NavPathStack = new NavPathStack()

  tabData: TabClass[] = [
    { text: '推荐', icon: $r('app.media.ic_recommend') },
    { text: '发现', icon: $r('app.media.ic_find') },
    { text: '动态', icon: $r('app.media.ic_moment') },
    { text: '我的', icon: $r('app.media.ic_mine') }
  ]

  @Builder tabBuilder(item: TabClass, index: number) {
    Column({ space: 5 }) {
      Image(item.icon)
        .width(24)
        .fillColor(this.index === index ? '#E85A88' : '#63AAAA')
      Text(item.text)
        .fontSize(14)
        .fontColor(this.index === index ? '#E85A88' : '#63AAAA')
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 黑色状态栏条（永不灰色！）
        Row()
          .width('100%')
          .height(26)
          .backgroundColor('#131215')

        Tabs({ barPosition: BarPosition.End, index: this.index }) {
          TabContent() {
            Recommend()
          }
          .tabBar(this.tabBuilder(this.tabData[0], 0))

          TabContent() {
            Find()
          }
          .tabBar(this.tabBuilder(this.tabData[1], 1))

          TabContent() {
            Moment()
          }
          .tabBar(this.tabBuilder(this.tabData[2], 2))

          TabContent() {
            Mine()
          }
          .tabBar(this.tabBuilder(this.tabData[3], 3))
        }
        .backgroundColor('#3B3F42')
        .animationDuration(150)
        .onChange((idx: number) => {
          this.index = idx;
        })
        .layoutWeight(1)
      }
      .backgroundColor('#131215')
    }
    .backgroundColor('#131215')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}