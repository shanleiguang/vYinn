
![image](https://github.com/shanleiguang/vYinn/blob/main/images/00.png)

### vYinn is 殷人

- 一款中文古籍電子印章設計和製作工具。它是本人中文古籍數字復刻計劃的一部分，配合vRain古籍電子書製作工具能夠生成更加古香古色的古籍復刻電子書。
- A tool for designing and producing electronic seals for Chinese ancient books.

![image](https://github.com/shanleiguang/vYinn/blob/main/images/02.png)

### 基本功能

- 簡單實用的設計排版輔助。

![image](https://github.com/shanleiguang/vYinn/blob/main/images/01.png)

- 印文支持陰文、陽文。
- 印框支持圓形、方形及橢圓。
- 印泥顏色可設置。
- 根據字體屬性，自動修正文字上下左右間距實現初步對齊。
- 每個文字可設置單獨字體大小、座標位置、橫縱變形比例、旋轉度數。
- 簡單的做殘、油墨、擴散效果。
- 可生成透明底色PNG文件，方便應用。
- 可從現有古籍印文圖片中扣取並生成新的透明底色印文圖片（y2y目錄下）。
- 初始配置文件可自動生成，所有參數均可通過配置文件管理。
- 采用 Perl 语言开发，需安装 Image::Magick 等模塊。
- 小紅書主頁：兀雨書屋。

![image](https://github.com/shanleiguang/vYinn/blob/main/images/03.png)

### 使用說明

- 查看 'config/blank.cfg'，瞭解畫布、印框、印文、效果四類參數的含義。
- 查看 'yins/' 目錄下的示例及其 'config/' 目錄下對應的配置文件。
- 使用 'new_config.pl' 腳本從 'config/blank.cfg' 初始化生成新印的 new.cfg，例如 perl new_config.pl -n 4,4 （4行4列）。
- 使用 'vyinn.pl' 帶 '-t' 參數繪制設計側圖，查看 'yins/' 目錄下帶 'test' 後綴圖片，調整配置文件中文字坐標等參數，重新生成測試圖片直至達到預期效果。
- 使用 'vyinn.pl' 無 '-t' 參數生成最終效果圖及應用圖（透明底色並裁切）。
- 'y2y/' 目錄下是從現有古籍印文圖片中扣取並生成新的透明底色印文圖片的腳本。

### 赞助支持 Other ways to sponsor

如果您覺得本工具對您的工作或生活有些微幫助，請給予必要的支持（一杯咖啡），我也有動力繼續完善更新，謝謝！贊助後，您可添加微信諮詢使用或代碼解讀等相關問題。  
If you feel that this tool is a little helpful to your work or life, please give the necessary support. After sponsorship, you can add WeChat consultation usage or code interpretation and other related questions.
![image](https://github.com/shanleiguang/vYinn/blob/main/sponsor.png)
