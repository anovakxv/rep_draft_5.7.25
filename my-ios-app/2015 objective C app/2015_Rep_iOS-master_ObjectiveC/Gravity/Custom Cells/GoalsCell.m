//
//  GoalsTableViewCell.m
//  Goals
//
//  Created by Ahad on 9/6/14.
//  Copyright (c) 2014 ahad. All rights reserved.
//

#import "GoalsCell.h"
#import "DataModel.h"

@implementation GoalsCell

- (void)awakeFromNib
{
    self.nameView.textContainer.lineFragmentPadding = 0;
    self.nameView.textContainerInset = UIEdgeInsetsZero;
    self.nameView.scrollEnabled = NO;
    self.nameView.textContainer.maximumNumberOfLines = 0;
    self.nameView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    if (self.preventSelection)
        return;
    
    self.backgroundColor = selected ? UIColorFromRGB(0xd9d9d9) : [UIColor whiteColor];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    if (self.preventSelection)
        return;
    
    self.backgroundColor = highlighted ? UIColorFromRGB(0xd9d9d9) : [UIColor whiteColor];
}

-(void)setGoal:(Goal *)goal {
    _goal = goal;
    barItems = goal.latestProgress.array;
    [self.barChart reloadData];
    
    //GoalMetrics *metrics = [DataModel getGoalMetricsWithId:goal.metricId];
    Portal *portal = [DataModel getPortalWithId:goal.portalId];
    GoalType *type = [DataModel getGoalTypeWithId:goal.typeId];
    
    self.metricLabel.text = [NSString stringWithFormat:@"%.0f%%", goal.progress.floatValue * 100];
    self.progressBar.progress = goal.progress.floatValue;
    self.metricLabel.text = [self.metricLabel.text stringByAppendingString:[NSString stringWithFormat:@" [%@]", type.name]];
    
    NSMutableAttributedString *info = [[NSMutableAttributedString alloc] init];
    [info.mutableString appendFormat:@"%@\n%@", portal.name.stringByStrippingHTMLItems, goal.about.stringByStrippingHTMLItems];
    [info addFont:[UIFont boldSystemFontOfSize:15] substring:portal.name.stringByStrippingHTMLItems];
    [info addFont:[UIFont systemFontOfSize:13] substring:goal.about.stringByStrippingHTMLItems];
    
    self.nameView.attributedText = info;
    
    //self.preventSelection = !goal.teamMember.boolValue;
}

#pragma mark barchart

- (NSUInteger)numberOfBarsInBarChart:(VGBarChart *)barChart {
    return barItems.count;
}

- (CGFloat)barChart:(VGBarChart *)barChart percentForBarAtIndex:(NSUInteger)index {
    
    Progress *progress = barItems[index];
    return progress.progress.floatValue;
}

@end
