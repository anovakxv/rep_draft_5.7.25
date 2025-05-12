//
//  SkillsViewController.m
//  Gravity
//
//  Created by Vlad Getman on 03.02.15.
//  Copyright (c) 2015 HalcyonInnovation. All rights reserved.
//

#import "SkillsViewController.h"

@interface SkillsViewController ()

@end

@implementation SkillsViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = @"Skills";
        
        NSMutableArray *aSkills = [[NSMutableArray alloc] init];
        NSArray *parentSkills = [DATA fetchData:@"Skill"
                                 withDescriptor:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]
                                  withPredicate:[NSPredicate predicateWithFormat:@"parentId == 0"]
                                 withAttributes:nil];
        for (Skill *skill in parentSkills) {
            [aSkills addObject:skill];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parentId == %@", skill.skillId];
            NSArray *childSkills = [DATA fetchData:@"Skill"
                                     withDescriptor:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]
                                      withPredicate:predicate
                                    withAttributes:nil];
            for (Skill *s in childSkills) {
                [aSkills addObject:s];
            }
        }
        skills = [NSArray arrayWithArray:aSkills];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

#pragma mark tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return skills.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MyIdentifier = @"MyIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
    }
    Skill *skill = skills[indexPath.row];
    BOOL parent = skill.parentId.integerValue == 0;
    cell.selectionStyle = parent ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
    cell.textLabel.font = [UIFont fontWithName:parent ? @"HelveticaNeue-Medium" : @"HelveticaNeue" size:parent ? 18 : 16];
    cell.textLabel.text = (parent ? skill.title : [@"      " stringByAppendingString:skill.title]).stringByStrippingHTMLItems;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Skill *skill = skills[indexPath.row];
    if (skill.parentId.integerValue == 0)
        return;
    
    if (self.selectionBlock)
        self.selectionBlock(skill.skillId);
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
