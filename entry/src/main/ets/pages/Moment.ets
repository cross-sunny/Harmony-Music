@Component
  // export 导出，别的组件才可以导入去使用
export struct Moment {
  build() {
    Text('动态')
      .fontColor('#fff')
  }
}