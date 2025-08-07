
# vYinn is  

- 一款中文古籍電子印章設計和製作工具。
- A tool for designing and producing electronic seals for Chinese ancient texts.

![image](https://github.com/shanleiguang/vYinn/blob/main/02.jpg)

# vYinn基本功能：

- 支持簡單的設計排版。

![image](https://github.com/shanleiguang/vYinn/blob/main/01.png)

- 印文支持陰文、陽文。
- 印框支持圓形、方形及橢圓。
- 每個文字可設置單獨字體大小、座標位置、橫縱變形比例、旋轉度數。
- 簡單的做殘、油墨、擴散效果。
- 可生成透明底色PNG文件，方便應用。
- 可從現有古籍印文圖片中扣取並生成新的透明底色印文圖片（y2y目錄下）。

![image](https://github.com/shanleiguang/vYinn/blob/main/03.png)

- 所有參數均可通過配置文件管理，初始配置文件可自動生成。
- 采用Perl语言开发，需安装Image::Magick等模塊。
- 小紅書主頁：兀雨書屋。

# vYinn使用说明：

- 查看'config/blank.cfg'了解画布、印框、印文、效果四类参数的含义。
- 查看'image'目录下的示例及其'config'目录下对应的配置文件。
- 使用'new_config.pl'脚本从'blank.cfg'初始化生成新印的new.cfg，例如./perl new_config -n 4,4 （4行4列）
- 使用'yinn.pl'带'-t'参数绘制设计侧图，打开'image'目录下带'test'后缀的图片，调整其配置文件中的文字坐标等参数。
- 使用'yinn.pl'不带'-t'参数生成最终效果图及应用图（透明底色并裁切）。
- y2y目录下是從現有古籍印文圖片中扣取並生成新的透明底色印文圖片的脚本。

# 赞助支持 Other ways to sponsor
如果您覺得本工具對您的工作或生活有些微幫助，請給予必要的支持（一杯咖啡），我也有動力繼續完善更新，謝謝！贊助後，您可添加微信諮詢使用或代碼解讀等相關問題。  
If you feel that this tool is a little helpful to your work or life, please give the necessary support. After sponsorship, you can add WeChat consultation usage or code interpretation and other related questions.
![image](https://github.com/shanleiguang/vYinn/blob/main/sponsor.png)
