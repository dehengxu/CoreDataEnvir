CoreDataEnvir
=============

A CoreData Envirement wrapper, use CoreData in convient way. You can use it in concurrency，run seperate CoreDataEnvir instance on one thread.

You can use it like:

##On main thread:

#Insert item:
	Team *team = [Team insertItem];
	or
	[Team insertItemWith:^(Team *item) {
		item.name = [NSString stringWithFormat:@"Nicholas"];
	}];
	
	[[CoreDataEnvir instance] saveDataBase];

#Fetch one item:
	Team *team = (Team *)[Team lastItemWith:[NSPredicate predicateWithFormat:@"name==nicholas"]];

#Fetch all items:
	NSArray *items = [Team itemsWith:[NSPredicate predicateWithFormat:@"name==nicholas"]];

#If you want to run on other threads, like this:

This method ([CoreDataEnvir instance]) will automatically creating new instance for non-main thread and uniq instance for main thread.

	dispatch_async(q2, ^{
		CoreDataEnvir *db = [CoreDataEnvir instance];
		for (int i = 0; i < 500; i++) {
			Team *team = (Team *)[Team lastItemWith:db predicate:[NSPredicate predicateWithFormat:@"name==9"]];
			if (team) {
				[db deleteDataItem:team];
			}else {
				[Team insertItemWith:db fillData:^(Team *item) {
					item.name = [NSString stringWithFormat:@"9"];
				}];
				
			}
			[db saveDataBase];
		}
	});


