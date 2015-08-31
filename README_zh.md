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

还有一个叫 "约翰史蒂芬" 的作者，写了一本传记叫 "拿破仑"

### 添加一个新记录

```Objective-C

[Book insertItemWithFillingBlock:^(id item) {
	item.name = @"约翰史蒂芬";
	item.author = @"拿破仑";
}];

```

### 查询一批记录

```Objective-C
//查询 约翰史蒂芬 写得所有书籍
NSArray *books= [Feed itemsWithFormat:@"author = %@",  @"约翰史蒂芬"];

```

### 查询一条记录

```Objective-C
//查找约翰史蒂芬写的拿破仑传记
Book *book = [Book lastItemWithFormat:@"name = %@ && author = %@", @"拿破仑", @"约翰史蒂芬"];

```

### 删除一条记录

```Objective-C
[CoreDataEnvir asyncMainInBlock:^(CoreDataEnvir *db) {
		[db deleteDataItem:book];
}];

```

### 删除多条记录

```Objective-C
[CoreDataEnvir asyncMainInBlock:^(CoreDataEnvir *db) {
		[db deleteDataItemSet:books];
}];
```

## 并发编程:

### On main thread

你可以在主线程上做一些轻量级的操作，但最好不要影响到你的UI响应。所有以上介绍的数据操作，默认都是必须运行在主线程上的，否则 CoreDataEnvir 自己会主动抛出异常。所以你要注意这方面的使用，如果你不确定当前是否主线程，可以这么做：

#### 你也可以明确地在主线程上使用 CoreDataEnvir

这样会让你感到比较有底一些：

```Objective-C
[CoreDataEnvir asyncMainInBlock:^(CoreDataEnvir *db) {
	[Book insertItemWithFillingBlock:^(id item) {
		item.name = @"拿破仑";
		item.author = @"约翰史蒂芬";
	}];
}];
```

### 在后台线程

CoreDataEnvir 也准备了一个后台 GCD 队列供你使用。

Block `asyncBackgroundInBlock` 将会在 `void(^)(CoreDataEnvir *db)` 调用结束后，自动将变动保存到数据库中。

你不必像老版本一样直接调用 `[db saveDataBase];` 。

```Objective-C

[CoreDataEnvir asyncBackgroundInBlock:^(CoreDataEnvir *db) {
	[Book insertItemOnBackgroundWithFillingBlock:^(id item) {
		item.name = @"拿破仑";
		item.author = @"约翰史蒂芬";
	}];
}];

```

这样在并发编程中 CoreData 的使用变得更加方便了。

### 几个快捷方法

必须在 GCD 主队列上运行：


* `+ (void)asyncMainInBlock:(void(^)(CoreDataEnvir *db))CoreDataBlock;`
* `+ (id)insertItemWithFillingBlock:(void(^)(id item))fillingBlock;`
* `+ (NSArray *)itemsWithFormat:(NSString *)fmt,...;`
...

必须在后台 GCD 队列上运行，你可以使用这些方法名称中包含 `Background` 的API：

* `+ (void)asyncBackgroundInBlock:(void(^)(CoreDataEnvir *db))CoreDataBlock;`
* `+ (id)insertItemOnBackgroundWithFillingBlock:(void(^)(id item))fillingBlock;`
* `+ (NSArray *)itemsOnBackgroundWithFormat:(NSString *)fmt,...;`
...

或者你想运行在你自己的 GCD 队列上，你可以选择这些 API：

* `+ (CoreDataEnvir *)createInstance;` you'd better hold this instance for future.
* `- (void)asyncInBlock:(void(^)(CoreDataEnvir *db))CoreDataBlock;`

## 如果你是一个 CoreData 新人，请遵守以下军规：

* 如果你想以后使用你的 NSManagedObject 对象，你不要释放 CoreDataEnvir 对象，否则模型对象都将失效。

* 如果你想在多线程上操作数据库，一定要确保每个线程有自己独立的 NSManagedObjectContext 对象。

> PS:在 CoreDataEnvir 中，请确保你的 NSManagedObject 对象是在主线程上从 [CoreDataEnvir mainInstance] 中获取的对象，或者在后台线程上从 [CoreDataEnvir backgroundInstance] 得到的对象。这两个对象是不会被释放的，通常情况下，CoreDataEnvir 提供的两个线程就能应付常见的并发情况了。
