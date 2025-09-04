#!/usr/bin/perl
#从'config/blank.cfg'空白配置文件创建新配置文件new.cfg，通常只需输入-n 4,4参数指定字数以生成坐标等参数
#by shanleiguang, 2025,06
use strict;
use warnings;

use Font::FreeType;
use Getopt::Std;
use Encode;
use utf8;

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

my %opts;

getopts('hc:f:t:s:n:', \%opts);

print_help() and exit if(defined $opts{'h'});

if(not defined $opts{'n'}) {
	print "\t'-n' 横、纵字符数未定义，例如 $0 -n 4,4\n";
	exit;
}

my %config;

open BLANKCFG, "< config/blank.cfg";
while(<BLANKCFG>) {
	chomp;
	next if(m/^\s{0,}$/);
	next if(m/^#/);
	s/\s+#.*$//;
	s/\s//g;
	my ($k, $v) = split /=/, $_;
	$v = decode('utf-8', $v);
	$config{$k} = $v;
}
close(BLANKCFG);

my $cw = $opts{'c'} ? (split /,/, $opts{'c'})[0] : $config{'canvas_width'};
my $ch = $opts{'c'} ? (split /,/, $opts{'c'})[1] : $config{'canvas_height'};
my $fw = $opts{'f'} ? (split /,/, $opts{'f'})[0] : $config{'frame_width'};
my $fh = $opts{'f'} ? (split /,/, $opts{'f'})[1] : $config{'frame_height'};
my $ytype = (defined $opts{'t'}) ? $opts{'t'} : 1;
my ($folw, $fold) = ($ytype == 1) ? split /,/, $config{'frame_outline1'} : split /,/, $config{'frame_outline0'};
my ($rows, $cols) = split /,/, $opts{'n'};
my ($zw, $zh) = (($fw-$folw*2-$fold*2)/$cols, ($fh-$folw*2-$fold*2)/$rows);
my $fs = $opts{'s'} ? $opts{'s'} : int(($zw <= $zh) ? $zw : $zh);
my ($coords, $trans, $fsizes) = ('', '', '');

foreach my $i (1..$cols) { #以行为列，配置文件第一行位置数组对应印章右起第一列字符位置
	foreach my $j (0..$rows-1) {
		my $cx = int($cw/2+$fw/2-$folw-$fold-$zw*$i+0.5); #向上取整
		my $cy = int($ch/2-$fh/2+$folw+$fold+$zh*$j+0.5);
		#print "cx:$cx cy:$cy\n";
		$coords.= "$cx,$cy|"; #形成字符位置数组
		$trans.= "1,1,0,0|"; #横纵拉伸比例，旋转角度
		$fsizes.= "$fs|"; #字体大小
	}
	$coords.= "/\n";
	$trans.= "/\n";
	$fsizes.= "/\n";
}

($config{'canvas_width'}, $config{'canvas_height'}) = ($cw, $ch);
($config{'frame_width'}, $config{'frame_height'}, $config{'yin_type'}) = ($fw, $fh, $ytype);
($config{'test_rows'}, $config{'test_cols'}) = ($rows, $cols);
$config{'yin_coords'} = "/\n".$coords;
$config{'yin_trans'} = "/\n".$trans;
$config{'yin_font_sizes'} = "/\n".$fsizes;
$config{'yin_text'} = '字'x($rows*$cols);

my $cfgfn = 'config/new.cfg';

open NEWCFG, "> $cfgfn";
print "\tcreate 'config/new.cfg' ...";
foreach my $k (sort keys %config) {
	print NEWCFG "$k=$config{$k}\n";
}
print "done\n";
close;

sub print_help {
	print <<END
   ./$0\t从'config/blank.cfg'空白配置创建新的印章配置文件'config/new.cfg'
    -c\t设置画布宽高（可选，默认值见blank.cfg） -n 1000,1000
    -f\t设置印框宽高（可选，默认值见blank.cfg） -f 500,500
    -l\t设置印文类型（可选，默认值见blank.cfg） -t 0或1
    -s\t设置印文字体大小（可选，默认自动计算） -s 110
    -n\t设置文字行列数，-n 3,4 三行四列
END
}


