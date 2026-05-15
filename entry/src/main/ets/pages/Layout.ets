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
      .animationDuration(150) // 【唯一新增的一行】：将动画时间缩短为150毫秒，既有动画又丝滑不黏手！
      .onChange((idx: number) => {
        this.index = idx;
      })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}