@Component
  // export 导出，别的组件才可以导入去使用
export struct Recommend {
  build() {
    Text('推荐')
      .fontColor('#fff')
  }
}