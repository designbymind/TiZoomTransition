#import "TiModule.h"

@interface TiZoomtransitionModule : TiModule

- (NSNumber *)isSupported:(id)unused;
- (void)prepareWindow:(id)args;
- (void)setSourceView:(id)args;
- (void)setAlignmentView:(id)args;
- (void)refreshAlignmentRect:(id)args;
- (void)clearWindow:(id)args;

@end
