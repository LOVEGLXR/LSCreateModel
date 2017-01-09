//
//  ViewController.m
//  生成model
//
//  Created by 刘松 on 16/12/1.
//  Copyright © 2016年 liusong. All rights reserved.
//

#import "ViewController.h"
#import "DragDropView.h"

@interface ViewController ()<DragDropViewDelegate>

@property (weak) IBOutlet NSTextField *tip;
@property (weak) IBOutlet NSTextField *createFileName;
@property (unsafe_unretained) IBOutlet NSTextView *text;
@property (weak) IBOutlet NSTextField *docTextField;
@property(nonatomic,strong)NSMutableArray * formateDicArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (IBAction)resetFormatCondition:(id)sender {
    [self.formateDicArr removeAllObjects];
}

- (IBAction)create:(id)sender {
    
    NSString *path = self.tip.stringValue;
    if ([[[self.text.string stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\t" withString:@""].length <= 0 && [self.tip.stringValue isEqualToString:@"文件存放目录"]) {
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert setMessageText:@"没有粘贴字符串到输入框或拖拽本地文件到弹窗中"];
        //[alert setInformativeText:@"副标题"];
        [alert addButtonWithTitle:@"取消"];
        //[alert addButtonWithTitle:@"取消"];
        
        [alert setAlertStyle:NSAlertStyleWarning];
        [alert beginSheetModalForWindow:nil modalDelegate:nil didEndSelector:nil contextInfo:nil];
        
        return;
    }
    
    if (self.createFileName.stringValue.length <=  0) {
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert setMessageText:@"请输入创建的类名"];
        //[alert setInformativeText:@"副标题"];
        [alert addButtonWithTitle:@"取消"];
        //[alert addButtonWithTitle:@"取消"];
        
        [alert setAlertStyle:NSAlertStyleWarning];
        [alert beginSheetModalForWindow:nil modalDelegate:nil didEndSelector:nil contextInfo:nil];
        return;
    }
    
    if ([[[self.text.string stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\t" withString:@""].length > 0){
        [self parse:self.text.string];
    }else{
        NSString *content = [NSString stringWithContentsOfFile:path    encoding:NSUTF8StringEncoding error:nil];
        [self parse:content];
    }
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"创建成功"];
    //[alert setInformativeText:@"副标题"];
    [alert addButtonWithTitle:@"取消"];
    //[alert addButtonWithTitle:@"取消"];
    
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert beginSheetModalForWindow:nil modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

-(NSString*)replace1WithContent:(NSString*)content regexStr:(NSString*)regexStr{
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:regexStr options: NSRegularExpressionCaseInsensitive error:NULL];
    
    NSArray *array2 = [regex matchesInString:content options:NSMatchingReportCompletion range:NSMakeRange(0, content.length)];
    
    NSMutableArray *replaceArray = [NSMutableArray array];
    for (NSTextCheckingResult *result in array2) {
        
        [replaceArray addObject:[content substringWithRange:result.range]];
    }
    for (NSString *str in replaceArray) {
        NSString *key = [str componentsSeparatedByString:@"\""].lastObject;
        content = [content stringByReplacingOccurrencesOfString:str withString:[NSString stringWithFormat:@"\"%@",key]];
    }
    return content;
}
-(NSString*)replace2WithContent:(NSString*)content regexStr:(NSString*)regexStr{
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:regexStr options: NSRegularExpressionCaseInsensitive error:NULL];
    
    NSArray *array2 = [regex matchesInString:content options:NSMatchingReportCompletion range:NSMakeRange(0, content.length)];
    
    NSMutableArray *replaceArray = [NSMutableArray array];
    for (NSTextCheckingResult *result in array2) {
        [replaceArray addObject:[content substringWithRange:result.range]];
    }
    
    for (NSString *str in replaceArray) {
    
        NSRegularExpression* regex2 = [NSRegularExpression regularExpressionWithPattern:@"[0-9]+" options: NSRegularExpressionCaseInsensitive error:NULL];
        
        NSArray *array2 = [regex2 matchesInString:str options:NSMatchingReportCompletion range:NSMakeRange(0, str.length)];

        NSString *re = str;
        if (array2.count>0) {
            NSTextCheckingResult *result = array2.firstObject;
            re = [re substringWithRange:result.range];
        }
        re = [str stringByReplacingOccurrencesOfString:re withString:@""];
        content = [content stringByReplacingOccurrencesOfString:str withString:re];
    }
    return content;
}

-(void)checkFormateDicWithDict:(NSDictionary*)dict{
    
    [self.formateDicArr addObject:dict];
    for (NSString *key in dict.allKeys) {
        id value = dict[ key];
        NSString *type = [[value class] description];
        NSLog(@"class ====== %@",type);
        NSString *content = @"";
        if([type rangeOfString:@"NSArray"].length > 0){//数组
            content = [NSString stringWithFormat:@"@property (nonatomic, strong) NSArray * %@;\n",key];
            NSArray *arr = value;
            if (arr.count > 0) {
                if ([arr.firstObject isKindOfClass:[NSDictionary class]]) {
                    [self checkFormateDicWithDict:arr.firstObject];
                }
            }
        }else if([type rangeOfString:@"NSDictionary"].length > 0){
            [self checkFormateDicWithDict:value];
        }
    }
}

-(void)createFileWithDict:(NSDictionary*)dict fileName:(NSString*)fileName
{
    NSString *deskTopLocation = [NSHomeDirectoryForUser(NSUserName()) stringByAppendingPathComponent:@"Desktop"];
    
    //以下两行生成一个文件目录
    NSString *hFilePath;
    NSString *mFilePath;
    
    if (self.docTextField.stringValue.length) {
        NSString * tempFilePath = [deskTopLocation stringByAppendingPathComponent:self.docTextField.stringValue];
        if (![[NSFileManager defaultManager] fileExistsAtPath:tempFilePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:tempFilePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        hFilePath = [tempFilePath stringByAppendingPathComponent: [NSString stringWithFormat:@"%@.h",fileName]];
        mFilePath = [tempFilePath stringByAppendingPathComponent: [NSString stringWithFormat:@"%@.m",fileName]];
    }
    
    NSString *hContent = @"";
    for (NSString *key in dict.allKeys) {
        id value = dict[ key];
        NSString *type = [[value class] description];
        NSLog(@"class ====== %@",type);
        NSString *content = @"";
        if ([type rangeOfString:@"NSCFBoolean"].length > 0) {
            // Bool 类型
            content = [NSString stringWithFormat:@"@property (nonatomic, assign) BOOL %@;\n",key];
        }else if([type rangeOfString:@"NSCFNumber"].length > 0){
            // NSCFNumber 类型
            content = [NSString stringWithFormat:@"@property (nonatomic, strong) NSNumber <Optional>* %@;\n",key];
        }else if([type rangeOfString:@"NSArray"].length > 0){//数组
            content = [NSString stringWithFormat:@"@property (nonatomic, strong) NSArray <ToReplaceModel,Optional>* %@;\n",key];
        }else if([type rangeOfString:@"NSDictionary"].length > 0){
            content = [NSString stringWithFormat:@"@property (nonatomic, strong) ToReplaceModel <Optional>* %@;\n",key];
        }else{
            // __NSCFString 或者 NSCFConstantString
            content = [NSString stringWithFormat:@"@property (nonatomic, copy) NSString <Optional>* %@;\n",key];
        }
        hContent = [hContent stringByAppendingString:content];
    }
    
    // .h文件
    NSString *fileHeader1 = [NSString stringWithFormat:@"//\n//  %@\n//  LangRen.h\n//\n//  Created by 酒诗 on 2016/12/20.\n//  Copyright © 2016年 langrengame.com. All rights reserved.\n//",fileName];
    NSString *hFile1 = @"\n#import <UIKit/UIKit.h>\n\n";
    NSString *hFile2 = [NSString stringWithFormat:@"@interface %@ : NSObject\n\n",fileName];
    NSString *fileFooter1 = @"\n@end\n\n";
    NSString *hFile = [NSString stringWithFormat:@"%@%@%@%@%@",fileHeader1,hFile1,hFile2,hContent,fileFooter1];
    [self runWriteWithContent:hFile path:hFilePath];
    
    // .m文件
    NSString *fileHeader2 = [NSString stringWithFormat:@"//\n//  %@.m\n//  LangRen\n//\n//  Created by 酒诗 on 2016/12/20.\n//  Copyright © 2016年 langrengame.com. All rights reserved.\n//",fileName];
    NSString *mFile1 = [NSString stringWithFormat:@"\n#import \"%@.h\"\n\n",fileName];
    NSString *mFile2 = [NSString stringWithFormat:@"@implementation %@\n",fileName];
    NSString *mFile = [NSString stringWithFormat:@"%@%@%@%@",fileHeader2,mFile1,mFile2,fileFooter1];
    [self runWriteWithContent:mFile path:mFilePath];
}

-(void)parse:(NSString*)content{
    
    if(!self.formateDicArr.count){
        content = [content stringByReplacingOccurrencesOfString:@" " withString:@""];
        content = [content stringByReplacingOccurrencesOfString:@"\t" withString:@""];
        
        //过滤掉因为复制粘贴带来的行号
        NSString *regexStr1 = @"[0-9]+\"[a-zA-Z0-9]+";
        content = [self replace1WithContent:content regexStr:regexStr1];
        
        NSString *regexStr2 = @"[^:][0-9]+[\\]\{\\}]";
        content = [self replace2WithContent:content regexStr:regexStr2];
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:(NSJSONReadingMutableContainers) error:NULL];
        [self checkFormateDicWithDict:dict];
    }
    
    if (self.formateDicArr.count){
        NSString *fileName = self.createFileName.stringValue;
        [self createFileWithDict:[self.formateDicArr firstObject] fileName:fileName];
        [self.formateDicArr removeObjectAtIndex:0];
        
        if(self.formateDicArr.count){
            self.createFileName.stringValue = @"";
            NSDictionary * dic = [self.formateDicArr firstObject];
            NSError *parseError = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
            NSString * dicJsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            self.text.string = dicJsonStr;
        }else {
            self.createFileName.stringValue = @"";
            self.text.string = @"";
        }
    }
}

-(void)runWriteWithContent:(NSString*)content path:(NSString*)path{
    //用上面的目录创建这个文件
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager createFileAtPath:path contents:nil attributes:nil];
    if (success) {
        NSLog(@"success");
    }
    //打开上面创建的那个文件
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
    [fileHandle seekToEndOfFile];//每次打开文件把光标定位在文末
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];//把这个字符串转换成数据格式用于写入文件里
    [fileHandle writeData:data];//写入文件
    [fileHandle closeFile];//关闭文件
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

/***
 第四步：实现dragdropview的代理函数，如果有数据返回就会触发这个函数
 ***/
-(void)dragDropViewFileList:(NSArray *)fileList{
    //如果数组不存在或为空直接返回不做处理（这种方法应该被广泛的使用，在进行数据处理前应该现判断是否为空。）
    if(!fileList || [fileList count]  <=   0)return;
    //在这里我们将遍历这个数字，输出所有的链接，在后台你将会看到所有接受到的文件地址
    for (int n = 0 ; n < [fileList count] ; n++) {
        NSString *path = [fileList objectAtIndex:n];
        NSLog(@"目录:%@",path);
        self.tip.stringValue = path;
    }
}

//获取字符串首字母(传入汉字字符串, 返回大写拼音首字母)
- (NSString *)getFirstLetterFromString:(NSString *)aString{
    //转成了可变字符串
    NSMutableString *str = [NSMutableString stringWithString:aString];
    //先转换为带声调的拼音
    CFStringTransform((CFMutableStringRef)str,NULL, kCFStringTransformMandarinLatin,NO);
    //再转换为不带声调的拼音
    CFStringTransform((CFMutableStringRef)str,NULL, kCFStringTransformStripDiacritics,NO);
    //转化为大写拼音
    NSString *strPinYin = [str capitalizedString];
    //获取并返回首字母
    return strPinYin ;
}

- (IBAction)look:(id)sender {
    [[NSWorkspace sharedWorkspace]openURL:[NSURL URLWithString:@"https://github.com/lsmakethebest/LSCreateModel"]];
}

-(NSMutableArray *)formateDicArr{
    if (!_formateDicArr) {
        self.formateDicArr = [NSMutableArray array];
    }
    return _formateDicArr;
}

@end
