// 1. interface 写在最顶部，抽离对象类型
interface StatItemType {
  value: string;
  label: string;
}

@ComponentV2
export struct Mine {
  // 2. 必传属性及状态变量初始化
  @Local stats: StatItemType[] = [
    { value: '1', label: '关注' },
    { value: '100万', label: '粉丝' },
    { value: '1.67亿', label: '赞' }
  ];

  build() {
    // 根节点 Column，背景色设置为你要求的 #131215，并加上扩展安全区
    Column() {

      // ==========================================
      // 需求1 & 2：图片区域，占高70%，堆叠布局，底部居中
      // ==========================================
      Stack({ alignContent: Alignment.Bottom }) {
        // 下层大图片背景 (这里假设你有一张名为 bg_album_wall 的拼图背景)
        Image($r('app.media.ad'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          // 文艺范小技巧：可以给背景图加一点点暗色遮罩，让上面的字更清晰
          .opacity(0.8)

        // 上层 Logo (悬浮在底部边缘)
        Image($r('app.media.logo'))
          .width(84)
          .height(84)
          .borderRadius(42) // 圆形Logo
          // 巧妙使用 offset 将 Logo 往下偏移自身高度的一半，实现跨界堆叠效果
          .offset({ y: 42 })
          .zIndex(2)
      }
      .width('100%')
      .height('70%') // 占高度 70%

      // ==========================================
      // 需求3：介绍区域，占高度30%
      // ==========================================
      // 规则：子组件控制间距尽量用 space 参数
      Column({ space: 18 }) {

        // 需求3.1：第一行为软件名字
        Row({ space: 8 }) {
          Text('黑马云音乐')
            .fontColor(Color.White)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(1) // 文艺范：稍微增加字间距

          // VIP 图标
          Image($r('app.media.ic_vip'))
            .height(20)
            .objectFit(ImageFit.Contain)
        }

        // 需求3.2：第二行为用户基本信息
        Row({ space: 15 }) {
          // 性别图标与文字组合
          Row({ space: 4 }) {
            Image($r('app.media.ic_vip')) // 假设有男性小图标
              .width(14)
              .fillColor('#5078A0') // 图标做一点低饱和度蓝，提升高级感
            Text('00后')
              .fontColor('#999999')
              .fontSize(13)
          }

          Text('双子座').fontColor('#999999').fontSize(13)
          Text('北京').fontColor('#999999').fontSize(13)
          Text('歌龄·18年').fontColor('#999999').fontSize(13)
        }

        // 需求3.3：第三行是账户信息（左右分散对齐）
        Row() {
          // 左侧：关注、粉丝、点赞数据
          Row({ space: 24 }) {
            // 规则：ForEach 循环必须添加类型，没用上的 _ 也必须添加类型
            ForEach(this.stats, (item: StatItemType, _: number) => {
              Row({ space: 4 }) {
                // 数字偏亮色，文字偏暗色，形成视觉层次
                Text(item.value)
                  .fontColor('#DDDDDD')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                Text(item.label)
                  .fontColor('#777777')
                  .fontSize(14)
              }
            }, (item: StatItemType) => item.label)
          }

          Blank() // 自动填充剩余空间，将右侧文字推到边缘

          // 右侧：黑马程序员 水印/标识
          Text('黑马程序员')
            .fontColor('#555555') // 更暗一点的灰色，低调不抢戏
            .fontSize(12)
        }
        .width('100%')
        .padding({ left: 40, right: 30 }) // 两侧留白
      }
      .width('100%')
      .height('30%') // 占高度 30%
      .padding({ top: 55 }) // 顶部留出 55 的内边距，给跨界偏移过来的 Logo 腾出空间
      .alignItems(HorizontalAlign.Center)

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#131215') // 背景色根据要求设置
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}