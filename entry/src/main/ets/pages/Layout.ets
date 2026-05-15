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
  // 重要：去掉 @Local，直接使用 Tabs 内置 index，状态完全同步！
  index: number = 0;
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
        // 直接用 TABS 自带的 index，完全实时同步！
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
      .onChange((idx: number) => {
        this.index = idx; // 完全实时同步
      })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}