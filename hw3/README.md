# GAMES202 homework3

## 完成
- 直接光照
- Screen Space Ray Tracing
- 间接光照


## 说明

### Bonus 1
- Mipmap加速实现在hw3-effective分支
- 由于Mipmap的生成需要反复读写framebuffer，且最终遍历次数与main分支相差无几，导致最终性能严重下降，仅供参考


## Result

### Cube1
![Cube1_D](./images/cube1直接光照.png)
![Cube1_DI](./images/cube1直接+间接.png)

### Cube2
![Cube2_D](./images/cube2直接光照.png)
![Cube2_DI](./images/cube2直接+间接.png)

### Cave
![Cave_D](./images/cave直接光照.png)
![Cave_DI](./images/cave直接+间接.png)
