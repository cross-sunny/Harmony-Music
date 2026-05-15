@Component
  // export 导出，别的组件才可以导入去使用
export struct Mine {
  build() {
    Text('我的')
      .fontColor('#fff')
  }
}