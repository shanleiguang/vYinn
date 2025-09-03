#!/usr/bin/perl
#vYinn - 殷人，兀雨书屋的中文古籍印章设计制作工具
#by shanleiguang@gmail.com, 2025/09
use strict;
use warnings;

use Image::Magick;
use Font::FreeType;
use Getopt::Std;
use Encode;
use utf8;

$| = 1; #autoflush

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

my ($software, $version) = ('vYinn', '1.1');
my %opts;

getopts('hc:', \%opts);

print_help() and exit if(defined $opts{'h'});

if(not defined $opts{'c'} or not -f "config/$opts{'c'}.cfg") {
	print "错误: 缺少印章配置文件参数或配置文件不存在， ./$0 -c 01\n";
	exit;
}

my $cid = $opts{'c'};
my $content;
#读取印章制作配置文件
open CONFIG, "< config/$cid.cfg";
{ local $/ = undef; $content = <CONFIG>; }
close(CONFIG);
$content =~ s/\/\n//g;

my @lines = split /\n/, $content;
my %yin;
foreach (@lines) {
	chomp;
	next if(m/^\s{0,}$/);
	next if(m/^#/);
	s/\s+#.*$//;
	s/\s//g;
	my ($k, $v) = split /=/, $_;
	$v = decode('utf-8', $v);
	$yin{$k} = $v;
}

#画布参数
my ($cw, $ch) = ($yin{'canvas_width'}, $yin{'canvas_height'});
#导出参数
my ($efc, $ebi, $ebc) = ($yin{'export_frame_crop'}, $yin{'export_background_image'}, $yin{'export_backgournd_color'});
#印框参数
my ($ft, $fw, $fh) = ($yin{'frame_type'}, $yin{'frame_width'}, $yin{'frame_height'});
my ($frr, $fcr, $fol0, $fol1) = ($yin{'frame_roundrectangle_radius'}, $yin{'frame_circle_radius'}, $yin{'frame_outline0'}, , $yin{'frame_outline1'});
my ($fea, $feb) = ($yin{'frame_ellipse_a'}, $yin{'frame_ellipse_b'});
my ($fol0w, $fol0d) = split /,/, $fol0; #阴文印框边框宽度，边框与文字内容的间距
my ($fol1w, $fol1d) = split /,/, $fol1; #阳文印框边框宽度，边框与文字内容的间距
#测试线参数
my ($trs, $tcs, $ts) = ($yin{'test_rows'}, $yin{'test_cols'}, $yin{'test_spacing'});
#印文参数
my ($ytext, $ytype, $yfont, $ycolor) = ($yin{'yin_text'}, $yin{'yin_type'}, 'fonts/'.$yin{'yin_font'}, $yin{'yin_color'});
my @ycoords = split /\|/, $yin{'yin_coords'}; #印文文字坐标
my @yfsizes = split /\|/, $yin{'yin_font_sizes'}; #印文文字大小
my @ytrans = split /\|/, $yin{'yin_trans'}; #印文文字拉伸、旋转
my $folw = ($ytype == 0) ? $fol0w : $fol1w; #根据印文阴阳类型选定
my $fold = ($ytype == 0) ? $fol0d : $fol1d;
#效果参数
my ($efsi, $efsr) = split /,/, $yin{'effect_frame_spread'}; #印框边缘扩散效果
my ($ecsi, $ecsr) = split /,/, $yin{'effect_chars_spread'}; #文字边缘扩散效果
my ($ebr, $ebs) = split /,/, $yin{'effect_blur'}; #整体模糊效果
my ($eop, $ebk) = ($yin{'effect_oilpaint'}, $yin{'effect_brokenspots'}); #整体油墨，随机残破斑点数量

print '='x80, "\n";
print "印章配置参数\n";
print '-'x80, "\n";
print "测线行列：$trs x $tcs\t测线间距：$ts\n";
print "画布宽度：$cw\t画布高度：$ch\n";
print "印框宽度：$fw\t印框高度：$fh\n";
print '印框类型：', ($ft == 0) ? '圆形' : ($ft == 1) ? '方形' : ($ft == 2) ? '圆角方形' : ($ft == 3) ? '椭圆形' : '无效', "\n";
print '印文类型：', ($ytype == 0) ? '0-阴文' : ($ytype == 1) ? '1-阳文' : '无效', "\n";
print "边框线宽：$folw\t边框间距：$fold\n";
print "印文字体：$yfont\n";
print "印文文字：$ytext\n";
print "印泥颜色：$ycolor（测试模式下白色代表印泥）\n";
print "导出背景：$ebc（通常设置为'transparent'）\n";
print '导出裁切：', ($efc == 0) ? '否' : ($efc == 1) ? '是，将按印框尺寸裁切' : '无效', "\n";
print '背景图片：', ($ebi) ? "$ebi, 同时生成该背景效果图" : '无', "\n";
print '='x80, "\n";

if(not -f $yfont) {
	print "错误: 印文字体文件 '$yfont' 不存在！\n";
	exit;
}

#注意：黑色代表透明，白色代表印泥，最后替代
#画布图层
my $yimg = Image::Magick->new();

$yimg->Set(size => $cw.'x'.$ch);
$yimg->ReadImage('canvas:black'); #画布背景为黑色

#测试图层
my $timg = $yimg->Clone();
#背景辅助线及坐标提示
foreach my $i (0..int($cw/$ts)) {
	$timg->Draw(primitive => 'line', points => get_2points($ts*$i, 0, $ts*$i, $ch), stroke => '#999999', strokewidth => 1);
	$timg->Annotate(text => $i, font => 'Courier', pointsize => 20, x => $ts*$i-30, y => 20, fill => 'white');
}
foreach my $j (0..int($ch/$ts)) {
	$timg->Draw(primitive => 'line', points => get_2points(0, $ts*$j, $cw, $ts*$j), stroke => '#999999', strokewidth => 1);
	$timg->Annotate(text => $j, font => 'Courier', pointsize => 20, x => 10, y => $ts*$j-5, fill => 'white');
}
#印框图层，边框线等同文字，因此印框线描边始终为白色，代表印泥色
my $fimg = Image::Magick->new();
my $ffc = ($ytype == 0) ? 'white' : 'black'; #印框内填充色，印文时为白色，代表印泥色

$fimg->Set(size => $fw.'x'.$fh);
$fimg->ReadImage('canvas:black');
#打印印框
if($ft == 0) { #圆形
	$fimg->Draw(primitive => 'ellipse', 
        points => get_points_ellipse($fw/2, $fh/2, $fcr, $fcr),
        fill => $ffc,
        stroke => 'white',
        strokewidth => $folw,
    );
	$fimg->Draw(primitive => 'ellipse', 
        points => get_points_ellipse($fw/2, $fh/2, $fcr-$folw/2-$fold/2, $fcr-$folw/2-$fold/2),
        fill => $ffc,
        stroke => 'black',
        strokewidth => $fold,
    ) if($fold > 0); #间距线描边为黑色，最后处理为透明，下同
}
if($ft == 1) { #方形
	$fimg->Draw(primitive => 'rectangle', points => get_2points($folw/2,$folw/2,$fw-$folw/2,$fh-$folw/2),
		fill => $ffc, stroke => 'white', strokewidth => $folw);
	$fimg->Draw(primitive => 'rectangle', points => get_2points($folw+$fold/2,$folw+$fold/2,$fw-$folw-$fold/2,$fh-$folw-$fold/2),
		fill => $ffc, stroke => 'black', strokewidth => $fold) if($fold > 0);
}
if($ft == 2) { #圆角方形
	$fimg->Draw(primitive => 'roundRectangle', points => get_3points($folw/2,$folw/2,$fw-$folw/2,$fh-$folw/2,$frr,$frr),
		fill => $ffc, stroke => 'white', strokewidth => $folw);
	$fimg->Draw(primitive => 'roundRectangle', points => get_3points($folw+$fold/2,$folw+$fold/2,$fw-$folw-$fold/2,$fh-$folw-$fold/2,$frr,$frr),
		fill => $ffc, stroke => 'black', strokewidth => $fold) if($fold > 0);
}
if($ft == 3) { #椭圆形
	$fimg->Draw(primitive => 'ellipse', 
        points => get_points_ellipse($fw/2, $fh/2, $fea, $feb),
        fill => $ffc,
        stroke => 'white',
        strokewidth => $folw,
    );
	$fimg->Draw(primitive => 'ellipse', 
        points => get_points_ellipse($fw/2, $fh/2, $fea-$folw/2-$fold/2, $feb-$folw/2-$fold/2),
        fill => $ffc,
        stroke => 'black',
        strokewidth => $fold,
    ) if($fold > 0);
}
#印框图层合并到测试图层
$timg->Composite(image => $fimg, x => ($cw-$fw)/2, y => ($ch-$fh)/2);
#印框图层合并到画布图层后添加边缘扩散效果后（印框图层无上下左右间距，因此先合并再添加边缘扩散效果）
$yimg->Composite(image => $fimg, x => ($cw-$fw)/2, y => ($ch-$fh)/2);
$yimg->Spread(radius => $efsr, interpolate => $efsi) if($efsr and $efsi);

#测试图层中继续添加测试辅助信息，始终注意白色代表印泥
my ($ftw, $fth) = (($fw-$folw*2-$fold*2)/$tcs, ($fh-$folw*2-$fold*2)/$trs);
#印文辅助线及坐标提示
foreach my $i (0..$trs) {
	my $ly = ($ch-$fh)/2+$folw+$fold+$fth*$i;
	$timg->Draw(primitive => 'line', points => get_2points(0,$ly,$cw,$ly), stroke => 'red', strokewidth => 1);
	$timg->Annotate(text => 'y:'.int($ly), font => 'Courier', pointsize => 20, x => ($cw-$fw)/2-100, y => $ly-10,
		fill => 'white', stroke => 'white', strokewidth => 1);
}
foreach my $j (0..$tcs) {
	my $lx = ($cw-$fw)/2+$folw+$fold+$ftw*$j;
	$timg->Draw(primitive => 'line', points => get_2points($lx,0,$lx,$ch), stroke => 'red', strokewidth => 1);
	$timg->Annotate(text => 'x:'.int($lx), font => 'Courier', pointsize => 20, x => $lx, y => 50+($ch-$fh-$folw*2-100)/2/$tcs*$j,
		fill => 'white', stroke => 'white', strokewidth => 1);
}
#测试图层左上角辅助信息
$timg->Draw(primitive => 'rectangle', points => get_2points(40, 40, 215, 80), fill => 'white');
$timg->Annotate(text => 'topleft:[0,0]', font => 'Courier', pointsize => 20, x => 50, y => 55, fill => 'black');
$timg->Annotate(text => 'white:YinNi', font => 'Courier', pointsize => 20, x => 50, y => 75, fill => 'black');
#测试图层右下角辅助信息
my ($iw, $ih, $is) = (300, 110, 15);
my ($ix, $iy) = ($cw-$iw-20, $ch-$ih-10);
$timg->Draw(primitive => 'rectangle', points => get_2points($ix, $iy, $ix+$iw, $iy+$ih), fill => 'white');
$timg->Annotate(text => "Canvas size: $cw x $ch", font => 'Courier', pointsize => $is, x => $ix+10, y => $iy+$is, fill => 'black');
$timg->Annotate(text => "Testline scale units: $ts", font => 'Courier', pointsize => $is, x => $ix+10, y => $iy+$is*2, fill => 'black');
$timg->Annotate(text => "Frame  size: $fw x $fh", font => 'Courier', pointsize => $is, x => $ix+10, y => $iy+$is*3, fill => 'black');
$timg->Annotate(text => "Frame outline width: $folw", font => 'Courier', pointsize => $is, x => $ix+10, y => $iy+$is*4, fill => 'black');
$timg->Annotate(text => "Frame outline distance: $fold", font => 'Courier', pointsize => $is, x => $ix+10, y => $iy+$is*5, fill => 'black');
$timg->Annotate(text => "Characters number: $trs x $tcs", font => 'Courier', pointsize => $is, x => $ix+10, y => $iy+$is*6, fill => 'black');
$timg->Annotate(text => "Yinn type: $ytype", font => 'Courier', pointsize => $is, x => $ix+10, y => $iy+$is*7, fill => 'black');

#打印印文文字
my $ytc = ($ytype == 0) ? 'black' : 'white'; #印文文字颜色，因为白色代表印泥色，所以阴文时文字为黑色，反之为白色
my @ychars = split //, $ytext;
my $freetype = Font::FreeType->new;
my $face = $freetype->face($yfont);
#逐个字符打印
foreach my $cid (0..$#ychars) {
	my $char = $ychars[$cid]; #印文字符
	my $cfs = $yfsizes[$cid]; #字符字体大小
	my ($cwr, $chr, $crd, $csw) = split /\,/, $ytrans[$cid]; #该字符的宽、高拉伸比例及旋转角度参数

	$face->set_char_size($cfs, $cfs, 72, 72);
	#获取该字符字体图像自身的上对齐、左对齐等数值
	my $glyph = $face->glyph_from_char($char);
	my $la = $glyph->left_bearing();
	my $ra = $glyph->right_bearing();
	my $va = $glyph->vertical_advance();
	my $gh = $glyph->height();
	#print "$char -> $la, $ra, $va\n";
	#创建字符独立图层
	my $cimg = Image::Magick->new();
	my ($chw, $chh) = ($cfs, $cfs+$va);

	$cimg->Set(size => $chw.'x'.$chh);
	$cimg->ReadImage('canvas:transparent');
	$cimg->Annotate(text => $char, font => '@'.$yfont, pointsize => $cfs, x => -$la, y => $cfs,
		fill => $ytc, stroke => $ytc, strokewidth => $csw, antialias => 'true', rotate => $crd); #写入字符，旋转变形
	$cimg->AdaptiveResize(width => $chw*$cwr, height => $chh*$chr); #长宽变形调整
	$cimg->Write("tmp/$char$cid.png") if($opts{'t'}); #测试模式时，单字图片存入tmp目录

	my ($cx, $cy) = split /,/, $ycoords[$cid]; #字符位置坐标
	$cid++; #数组坐标从0开始，+1为字符序号
	$cid = '0'.$cid if($cid <= 9);
	print "->[$cid]'$char' 坐标：($cx,$cy），大小：$cfs, 变形：（长x$cwr, 宽x$chr, 旋转$crd, 描边$csw）\n";
	$timg->Composite(image => $cimg, x => $cx, y => $cy); #合并到印文图层对应坐标位置
	$cimg->Spread(radius => $ecsr, interpolate => $ecsi) if($ecsr and $ecsi); #文字边缘扩散效果
	$yimg->Composite(image => $cimg, x => $cx, y => $cy); #合并到印文图层对应坐标位置
}

my $yinfn = $cid.'_'.$ytype;

print '='x80, "\n";

if($ebk) { #添加印框范围内的随机大小的椭圆斑点图层
	foreach my $i (1..$ebk) {
    	my ($px, $py) = (int(rand($fw)), int(rand($fh))); #印框范围内随机位置
    	my $size = 5+int(rand(10)); #斑点大小
    	my $point = Image::Magick->new();

    	$point->Set(size => $size.'x'.$size);
    	$point->ReadImage('canvas:transparent');
    	$point->Draw(primitive => 'ellipse',
        	points => get_points_ellipse($size/2, $size/2, $size*0.3, $size*0.2),
        	fill => 'black', 
    	);
    	$point->Rotate(degrees => rand(45)-22.5); #旋转角度
    	$point->OilPaint(radius => 1.5); #油墨化
    	$point->AdaptiveBlur(radius => 2.2, sigma => 1, bias => -1); #模糊处理
    	$yimg->Composite(image => $point, x => ($cw-$fw)/2+$px, y => ($ch-$fh)/2+$py, compose => 'Multiply'); #合并到印文图层
	}
}

#印稿黑白色替换为印章配置中的印泥色及印章背景色
$yimg->AutoThreshold('OTSU');
$yimg->Colorspace('RGB');
$yimg->Opaque(color => 'white', fill => $ycolor, invert => 'false'); #白色替换为印泥色
$yimg->Opaque(color => 'black', fill => $ebc, invert => 'false'); #黑色替换为指定背景色
#添加整体模糊、油墨效果
$yimg->AdaptiveBlur(radius => $ebr, sigma => $ebs) if($ebr and $ebs);
$yimg->OilPaint(radius => $eop) if($eop);
#测试图层扩展添加效果预览图
$timg->Extent(width => $cw*2+$ts, height => $ch, x => 0, y => 0, background => 'white');
$timg->Composite(image => $yimg, x => $cw+$ts, y => 0, compose => 'Over');
$timg->Write("test/$yinfn.jpg");

#导出操作
#沿印框边缘裁切
if($efc) {
	$yimg->Crop(width => $fw+4, height => $fh+4, x => ($cw-$fw)/2-2, y => ($ch-$fh)/2-2);
}
$yimg->Write("yins/$yinfn.png");
print "已保存到'yins/$yinfn.png'\n";
#如果印底为透明色且设置了宣纸背景图片，则额外生成一张宣纸背景的效果图，可用于展示
if($ebi and $ebc =~ m/^transparent$/i) {
	my $paper = Image::Magick->new();
	my ($yw, $yh) = ($yimg->Get('width'), $yimg->Get('height'));
	$paper->ReadImage('images/'.$ebi);
	$paper->Crop(width => $cw, height => $ch, x => rand(100), y => rand(100));
	$paper->Composite(image => $yimg, x => ($cw-$yw)/2, y => ($ch-$yh)/2);
	$paper->Write('yins/'.$yinfn.'_paper.jpg');
	print "宣纸背景效果图已保存到'yins/$yinfn", '_paper.jpg', "\n";
}
print '='x80, "\n";

sub print_help {
	print <<END
   ./$software $version，殷人 — 兀雨书屋古籍印章设计制作工具
	-h 帮助信息
	-c 印章配置文件名
	*运行后查看'test'目录下该印章带测试辅助信息的图片，调整印章cfg参数后重新运行
	*直至达到预期效果，到'yins'目录查看印章最终生成图
		作者：GitHub\@shanleiguuang，小红书\@兀雨书屋，2025
END
}

sub get_2points {
	my ($x1, $y1, $x2, $y2) = @_;
	return "$x1,$y1 $x2,$y2";
}

sub get_3points {
	my ($x1, $y1, $x2, $y2, $x3, $y3) = @_;
	return "$x1,$y1 $x2,$y2 $x3,$y3";
}

sub get_points_ellipse {
	my ($fx, $fy, $tx, $ty) = @_;
	return "$fx,$fy $tx,$ty 0,360";
}

