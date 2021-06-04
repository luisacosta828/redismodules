# redismodules
Develop redis modules in Nimlang (WIP)
# Usage

### Install redismodules
```nim 
nimble install redismodules@#head 
```
### Write your module
```nim

import redismodules

proc HelloRedis(ctx: ptr Ctx, argv: ptr ptr String, argc: cint):cint {. exportc, dynlib .} =
    result = ReplyWithSimpleString(ctx,"nimlang redismodule ;)")

proc RedisModule_OnLoad(ctx: ptr Ctx, argv: ptr ptr String, argc: cint):cint {. exportc, dynlib .} =
     discard Init(ctx,"helloworld",1,1)
     result = CreateCommand(ctx,"helloworld.hello", HelloRedis, "readonly",0, 0, 0)

```
### Build a dynamic library
```nim

nim c -d:release --app:lib [filename.nim]
```
### Load your dynlib into your redis server
``` bash
redis-server --loadmodule [fullpath of your module].so
#output 
* Module 'helloworld' loaded 
```

### Start using your module
```bash
127.0.0.1:6379> helloworld.hello
#nimlang redismodule ;)

```
