#pragma definitions
{.pragma: opaqueType, exportc: "RedisModule$1", incompleteStruct.}
{.pragma: redis_extern, exportc:"RedisModule_$1", dynlib.}

#opaque types definitions
type 
    const_char_pp {.importc:"const char *".} = cstring
    Ctx* {.opaqueType.} = object
    String* {.opaqueType.} = object
    CallReply* {.opaqueType.} = object    

    Argv = ptr UncheckedArray[ptr String]
    
#function pointers definitions
type
    CmdFunc* {.exportc: "RedisModule$1".} = proc(ctx: ptr Ctx, 
                                                 argv: ptr ptr String, 
                                                 argc: cint):cint {. cdecl .}

var Alloc {.redis_extern.}: proc(bytes: csize): pointer {. cdecl .}

var AutoMemory* {.redis_extern.}: proc(ctx: ptr Ctx){. cdecl .}

var Realloc {.redis_extern.}: proc(`ptr`: pointer, bytes:csize):pointer {. cdecl .}

var GetApi {.redis_extern.}: proc(name: const_char_pp, data: pointer): cint {.cdecl.}

var SetModuleAttribs {.redis_extern.}: proc(ctx: ptr Ctx, name: const_char_pp, ver, apiver: cint) {.cdecl.} 

var IsModuleNameBusy {.codegenDecl: "$1 $2".}: proc(name: const_char_pp):cint {. cdecl .}

var ReplyWithLongLong* {.redis_extern.}: proc(ctx: ptr Ctx, ll: clonglong):cint {.cdecl.}

var ReplyWithSimpleString* {.redis_extern.}: proc(ctx: ptr Ctx, msg: const_char_pp): cint {.cdecl.}

var ReplyWithArray* {.redis_extern.}: proc(ctx: ptr Ctx, len: clong):cint {.cdecl.}

var ReplySetArrayLength* {.redis_extern.}: proc(ctx: ptr Ctx, len: clong) {.cdecl.}

var ReplyWithError* {.redis_extern.}: proc(ctx: ptr Ctx, err: const_char_pp): cint {.cdecl.}

var ReplyWithNull* {.redis_extern.}: proc(ctx: ptr Ctx):cint {.cdecl.}

var CreateCommand* {. redis_extern .}: proc(ctx: ptr Ctx,name: const_char_pp, 
                                    cmdfunc: CmdFunc, strflags: const_char_pp,
                                    firstkey, lastkey, keystep: cint):cint {. cdecl .}

var GetSelectedDb* {.redis_extern.}: proc(ctx: ptr Ctx):cint {.cdecl.}
var SelectDb* {.redis_extern.}: proc(ctx: ptr Ctx, newid: cint):cint {.cdecl.}
var GetClientId* {.redis_extern.}: proc(ctx: ptr Ctx):culonglong {.cdecl.}

var StringPtrLen* {.redis_extern.}: proc(str: ptr String, len: ptr csize): const_char_pp {.cdecl.}

var StringToDouble* {.redis_extern.}: proc(str: ptr String, d: ptr cdouble): cint {. cdecl .}
var StringToLongLong* {.redis_extern.}: proc(str: ptr String, ll: ptr clonglong): cint {. cdecl .}

var WrongArity* {.redis_extern.}: proc(ctx: ptr Ctx,):cint {.cdecl.}

var Call* {.redis_extern.}: proc(ctx: ptr Ctx, cmdname: const_char_pp, fmt: const_char_pp):ptr CallReply {.cdecl, varargs.}

var CallReplyType* {.redis_extern.}: proc(reply: ptr CallReply):cint {. cdecl .}

var CallReplyInteger* {.redis_extern.}: proc(reply: ptr CallReply):clonglong {. cdecl .}


template GetRedisApi(data: untyped) = discard GetApi("RedisModule_" & data.astToStr,cast[pointer](data.addr))

proc Init*(ctx: ptr Ctx, name: const_char_pp, ver, apiver: cint):cint {. redis_extern .} = 

     let getapifuncptr:pointer = cast[ptr UncheckedArray[pointer]](ctx)[0]
     GetApi = cast[proc(name: const_char_pp, data: pointer): cint {.cdecl.}](cast[culong](getapifuncptr))
     
     GetRedisApi(Alloc)
     GetRedisApi(AutoMemory)
     GetRedisApi(Realloc)
     GetRedisApi(CreateCommand)

     GetRedisApi(ReplyWithLongLong)
     GetRedisApi(ReplyWithSimpleString)
     GetRedisApi(StringPtrLen)
     GetRedisApi(ReplyWithArray)
     GetRedisApi(ReplySetArrayLength)
     GetRedisApi(StringToDouble)
     GetRedisApi(StringToLongLong)
     GetRedisApi(SetModuleAttribs)
     GetRedisApi(WrongArity) 
     GetRedisApi(ReplyWithError)
     GetRedisApi(ReplyWithNull)

     GetRedisApi(GetSelectedDb)     
     GetRedisApi(SelectDb)
     GetRedisApi(GetClientId)

     GetRedisApi(Call)
     GetRedisApi(CallReplyType)
     GetRedisApi(CallReplyInteger)
     SetModuleAttribs(ctx,name,ver,apiver)

     result = 0

#Utilities
proc toArgv*(argv: ptr ptr String):auto {. inline .} = cast[Argv](argv)

proc getDouble*(argv: ptr ptr String, pos:cint, value: ptr cdouble) =
     var a = argv.toArgv
     if StringToDouble(a[pos],value) == 0:
        echo "StringToDouble: ok"
     else:
        echo "StringToDouble: not ok"


proc getLongLong*(argv: ptr ptr String, pos:cint, value: ptr clonglong) =
     var a = argv.toArgv
     if StringToLongLong(a[pos],value) == 0:
        echo "StringToLongLong: ok"
     else:
        echo "StringToLongLong: not ok"

proc getValue*(argv: ptr ptr String,pos:cint): const_char_pp  = 
   var a = argv.toArgv
   StringPtrLen(a[pos],nil)

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
    
        
#Command Wrappers
proc dispatch_reply_method(reply: ptr CallReply):auto =
    if not reply.isNil:
       result = case CallReplyType(reply):
            of 2: CallReplyInteger(reply) 
            else: -1
                
proc set*(ctx: ptr Ctx, key:string, value: string) = discard Call(ctx,"SET","cc",key,value)
         
proc incr*(ctx: ptr Ctx, key:string):auto = Call(ctx,"INCR","c",key).dispatch_reply_method

proc incrBy*(ctx: ptr Ctx, key:string, value: string):auto = Call(ctx,"INCRBY","cc",key,value).dispatch_reply_method

