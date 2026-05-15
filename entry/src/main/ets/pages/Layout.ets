import { Recommend } from "./Recommend";
import { Find } from "./Find";
import { Moment } from "./Moment";
import { Mine } from "./Mine";

interface TabClass {
  text: string
  icon: ResourceStr
}

// 跳转页面入口函数
@Builder
export function LayoutBuilder() {
  Layout()
}

@ComponentV2
struct Layout {
  @Local currentIndex: number = 0;
  // 控制跳转的对象
  pathStack: NavPathStack = new NavPathStack()

  tabData: TabClass[] = [
    { text: '推荐', icon: $r('app.media.ic_recommend') },
    { text: '发现', icon: $r('app.media.ic_find') },
    { text: '动态', icon: $r('app.media.ic_moment') },
    { text: '我的', icon: $r('app.media.ic_mine') }
  ]

  // 自定义 tabBar 的 @Builder 函数（完全按截图修改）
  @Builder tabBuilder(item: TabClass, index: number) {
    Column({ space: 5 }) {
      Image(item.icon)
        .width(24)
        .fillColor(this.currentIndex === index ? '#E85A88' : '#63AAAA')
      Text(item.text)
        .fontSize(14)
        .fontColor(this.currentIndex === index ? '#E85A88' : '#63AAAA')
    }
  }

  build() {
    NavDestination() {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        ForEach(this.tabData, (item: TabClass, index: number) => {
          TabContent() {
            if (this.currentIndex === 0) {
              Recommend()
            } else if (this.currentIndex === 1) {
              Find()
            } else if (this.currentIndex === 2) {
              Moment()
            } else if (this.currentIndex === 3) {
              Mine()
            }
          }
          .tabBar(this.tabBuilder(item, index)) // 调用上面的 @Builder 构建自定义导航栏
          .backgroundColor('#131215')
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        })
      }
      .backgroundColor('#3B3F42')
      .onChange((index: number) => {
        this.currentIndex = index
      })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    // .title('布局页')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}