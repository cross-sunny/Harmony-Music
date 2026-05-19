// 跳转页面入口函数
@Builder
export function StartBuilder() {
  Start()
}

@Component
struct Start {
  pageStack: NavPathStack = new NavPathStack()

  // 过3秒钟自动跳转到 Layout → Start 页面打开计时 3秒后跳转
  aboutToAppear(): void { // 生命周期
    setTimeout(() => {
      this.pageStack.replacePathByName("Layout", null, false)
    }, 1000) // 毫秒为单位 1000毫秒 = 1秒
  }

  build() {
    NavDestination() {
      // Button('点击跳转到 Layout ')
      //   .onClick(() => {
      //     this.pageStack.pushPathByName("Layout", null, false)
      //   })

      Stack({ alignContent: Alignment.TopEnd }) {
        Image($r('app.media.ad'))
          .width('100%')
          .height('100%')
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

        // Button('跳过')
        //   .backgroundColor(Color.Grey)
        //   .margin(15)
        //   .onClick(() => {
        //     this.pageStack.replacePathByName("Layout", null, false)
        //     // this.pageStack.pushPathByName("Layout", null, false)
        //   })
      }
    }
    // .title('广告页')
    .onReady((context: NavDestinationContext) => {
      this.pageStack = context.pathStack
    })
  }
}