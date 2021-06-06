{.pragma: opaqueType, exportc: "RedisModule$1", incompleteStruct.}
{.pragma: redis_extern, exportc:"RedisModule_$1", dynlib.}

#opaque types definitions
type 
    const_char_pp {.importc:"const char *".} = cstring
    Ctx* {.opaqueType.} = object
    String* {.opaqueType.} = object

#function pointers definitions
type
    CmdFunc* {.exportc: "RedisModule$1".} = proc(ctx: ptr Ctx, 
                                                 argv: ptr ptr String, 
                                                 argc: cint):cint {. cdecl .}

var Alloc* {.redis_extern.}: proc(bytes: csize): pointer {. cdecl .}

var Realloc* {.redis_extern.}: proc(`ptr`: pointer, bytes:csize):pointer {. cdecl .}

var GetApi* {.redis_extern.}: proc(name: const_char_pp, data: pointer): cint {.cdecl.}

var SetModuleAttribs* {.redis_extern.}: proc(ctx: ptr Ctx, name: const_char_pp, ver, apiver: cint) {.cdecl.} 

var IsModuleNameBusy* {.codegenDecl: "$1 $2".}: proc(name: const_char_pp):cint {. cdecl .}

var ReplyWithLongLong* {.redis_extern.}: proc(ctx: ptr Ctx, ll: clonglong):cint {.cdecl.}

var ReplyWithSimpleString* {.redis_extern.}: proc(ctx: ptr Ctx, msg: const_char_pp): cint {.cdecl.}

var ReplyWithArray* {.redis_extern.}: proc(ctx: ptr Ctx, len: clong):cint {.cdecl.}

var ReplySetArrayLength* {.redis_extern.}: proc(ctx: ptr Ctx, len: clong) {.cdecl.}

var CreateCommand* {. redis_extern .}: proc(ctx: ptr Ctx,name: const_char_pp, 
                                    cmdfunc: CmdFunc, strflags: const_char_pp,
                                    firstkey, lastkey, keystep: cint):cint {. cdecl .}

#template GetRedisApi(name: cstring, data: untyped) = discard GetApi("RedisModule_" & name, cast[pointer](data.addr))
template GetRedisApi(data: untyped) = discard GetApi("RedisModule_" & data.astToStr, cast[pointer](data.addr))

proc Init*(ctx: ptr Ctx, name: const_char_pp, ver, apiver: cint):cint {. redis_extern .} = 

     let getapifuncptr:pointer = cast[ptr UncheckedArray[pointer]](ctx)[0]
     GetApi = cast[proc(name: const_char_pp, data: pointer): cint {.cdecl.}](cast[culong](getapifuncptr))

     GetRedisApi(Alloc)
     GetRedisApi(Realloc)
     GetRedisApi(CreateCommand)

     GetRedisApi(ReplyWithLongLong)
     GetRedisApi(ReplyWithSimpleString)
     GetRedisApi(ReplyWithArray)
     GetRedisApi(ReplySetArrayLength)

     GetRedisApi(SetModuleAttribs)
     SetModuleAttribs(ctx,name,ver,apiver)

     result = 0

proc arrayOf*(ctx: ptr Ctx, data:seq, datatype: string):cint {. inline .} = 
    discard ReplyWithArray(ctx,data.len)
    for item in data: 
        case datatype:
            of "ll":
                discard ReplyWithLongLong(ctx,cast[clonglong](item))
            of "s":
                discard ReplyWithSimpleString(ctx,$item)
            else: 
                result = 1
    
        
