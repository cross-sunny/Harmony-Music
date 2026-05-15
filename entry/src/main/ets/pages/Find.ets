@Component
  // export 导出，别的组件才可以导入去使用
export struct Find {
  build() {
    Text('发现')
      .fontColor('#fff')
  }
}