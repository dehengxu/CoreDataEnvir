CoreDataEnvir (since 2011-05-25) latest version 0.4
=============

CoreDataEnvir 是一个 CoreData 框架的封装。提供了一种简单的方式来使用 CoreData ，它也为你的并发编程提供了线程安全支持。你可以在每个线程上运行一个单独的实例来进行并发编程。

## 第一步:

注册你的数据库文件名

```Objective-C
	[CoreDataEnvir registDatabaseFileName:@"db.sqlite"];
```

注册你的模型文件名(不包含文件扩展名)

```Objective-C
	[CoreDataEnvir registModelFileName:@"SampleModel"];
```

## 简单的数据库访问:

我们假设 `Book` 类是你的App中一个代表书籍对象的模型类。它有一些成员域 `name`, `author` 等等。

There is an author "John Stevens Cabot Abbott" written a book named "Napoleon Bonnaparte".
有一个叫 ""

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
