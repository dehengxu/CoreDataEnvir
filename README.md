CoreDataEnvir (since 2011-05-25) latest version 0.4
=============

CoreDataEnvir is a CoreData wrapper which use CoreData in convient way and supply simple thread safe in concurrenct programming. You can use it concurrenctly，run seperate CoreDataEnvir instance on one thread.

## First step:

Register your data base file name

```Objective-C
	[CoreDataEnvir registDatabaseFileName:@"db.sqlite"];
```

Register your model file name(no file extension name)

```Objective-C
	[CoreDataEnvir registModelFileName:@"SampleModel"];
```

## Simple data base access:

Let's assumption the `Book` class is a model which represent a book object in your reading app. It has some field are `name`, `author` ... etc.

There is an author "John Stevens Cabot Abbott" written a book named "Napoleon Bonnaparte".

### Add new record

```Objective-C

[Book insertItemWithFillingBlock:^(id item) {
	item.name = @"CoreData tutorial";
	item.author = @"Headwindx";
}];

```

### Fetch lots of records

```Objective-C
//Find all books of John Stevens Cabot Abbott.
NSArray *books= [Feed itemsWithFormat:@"author = %@",  @"John Stevens Cabot Abbott"];

```

### Fetch one record

```Objective-C
//Find one book model object.
Book *book = [Book lastItemWithFormat:@"name = %@ && author = %@", @"Napoleon Bonnaparte", @"John Stevens Cabot Abbott"];

```

### Delete one record

```Objective-C
[CoreDataEnvir asyncMainInBlock:^(CoreDataEnvir *db) {
		[db deleteDataItem:book];
}];

```

### Delete records

```Objective-C
[CoreDataEnvir asyncMainInBlock:^(CoreDataEnvir *db) {
		[db deleteDataItemSet:books];
}];
```

## Concurrenct programming:

### On main thread

You can do some lightweight operation on main thread. All of above operation must runs on main thread by default or it will raise an exception by `CoreDataEnvir`. So you should be carefully.

#### You also can explicit use on main thread

It makes you feel more safe :-)

```Objective-C
[CoreDataEnvir asyncMainInBlock:^(CoreDataEnvir *db) {
	[Book insertItemWithFillingBlock:^(id item) {
		item.name = @"CoreData tutorial";
		item.author = @"Headwindx";
	}];
}];
```

### On background thread

It's already prepared a background GCD queue for you in `CoreDataEnvir`.

The block `asyncBackgroundInBlock` will save memory cache to db file after `void(^)(CoreDataEnvir *db)` works finished.

You don't need to use `[db saveDataBase];` like older version.

```Objective-C

[CoreDataEnvir asyncBackgroundInBlock:^(CoreDataEnvir *db) {
	[Book insertItemOnBackgroundWithFillingBlock:^(id item) {
		item.name = @"CoreData tutorial";
		item.author = @"Headwindx";
	}];
}];

```

It becomes more conveniently on concurrenct programming.

### Convenient methods

Must run on main queue:


* `+ (void)asyncMainInBlock:(void(^)(CoreDataEnvir *db))CoreDataBlock;`
* `+ (id)insertItemWithFillingBlock:(void(^)(id item))fillingBlock;`
* `+ (NSArray *)itemsWithFormat:(NSString *)fmt,...;`
...

Must run on background queue, you can use these APIs and some methods name within `Background`:

* `+ (void)asyncBackgroundInBlock:(void(^)(CoreDataEnvir *db))CoreDataBlock;`
* `+ (id)insertItemOnBackgroundWithFillingBlock:(void(^)(id item))fillingBlock;`
* `+ (NSArray *)itemsOnBackgroundWithFormat:(NSString *)fmt,...;`
...

Or you wanna run some operation in your own dispatch queue, you can choose this APIs:

* `+ (CoreDataEnvir *)createInstance;` you'd better hold this instance for future.
* `- (void)asyncInBlock:(void(^)(CoreDataEnvir *db))CoreDataBlock;`

## If your are newcomer to CoreData, please obey the rules below:

If you wanna keep you NSManagedObject objects, you shouldn't release you CoreDataEnvir object or it will be fault. So if you operate data base in multiple threads, make sure your NSManagedObject object reference fetched from [CoreDataEnvir mainInstance] or [CoreDataEnvir backgroundInstance] which never be released until application exist and it's enough for usual.
