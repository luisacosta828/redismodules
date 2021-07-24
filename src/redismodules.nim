import tables
import strutils
import macros

#pragma definitions
{.pragma: opaqueType, exportc: "RedisModule$1", incompleteStruct.}
{.pragma: redis_extern, exportc:"RedisModule_$1", dynlib.}

#opaque types definitions
type 
    const_char_pp* {.importc:"const char *".} = cstring
    Ctx* {.opaqueType.} = object
    PCtx* = ptr Ctx
    String* {.opaqueType.} = object
    PPString* = ptr ptr String
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

var ReplyWithDouble* {.redis_extern.}: proc(ctx: ptr Ctx, d: cdouble):cint {.cdecl.}

var ReplyWithSimpleString* {.redis_extern.}: proc(ctx: ptr Ctx, msg: const_char_pp): cint {.cdecl.}

var ReplyWithArray* {.redis_extern.}: proc(ctx: ptr Ctx, len: clong):cint {.cdecl.}

var ReplySetArrayLength* {.redis_extern.}: proc(ctx: ptr Ctx, len: clong) {.cdecl.}

var ReplyWithError* {.redis_extern.}: proc(ctx: ptr Ctx, err: const_char_pp): cint {.cdecl.}

var ReplyWithNull* {.redis_extern.}: proc(ctx: ptr Ctx):cint {.cdecl.}

var CreateCommand* {. redis_extern .}: proc(ctx: ptr Ctx,name: const_char_pp, 
                                    cmdfunc: CmdFunc, strflags: const_char_pp,
                                    firstkey, lastkey, keystep: cint = 0):cint {. cdecl .}

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

var CallReplyStringPtr* {.redis_extern.}: proc(reply: ptr CallReply,len: ptr csize):const_char_pp {. cdecl .}

var CallReplyArrayElement* {.redis_extern.}: proc(reply: ptr CallReply,idx: csize):ptr CallReply {. cdecl .}

template GetRedisApi(data: untyped) = discard GetApi("RedisModule_" & data.astToStr,cast[pointer](data.addr))

proc Init*(ctx: ptr Ctx, name: const_char_pp, ver, apiver: cint = 1):cint {. redis_extern .} = 

     let getapifuncptr:pointer = cast[ptr UncheckedArray[pointer]](ctx)[0]
     GetApi = cast[proc(name: const_char_pp, data: pointer): cint {.cdecl.}](cast[culong](getapifuncptr))
     
     GetRedisApi(Alloc)
     GetRedisApi(AutoMemory)
     GetRedisApi(Realloc)
     GetRedisApi(CreateCommand)

     GetRedisApi(ReplyWithLongLong)
     GetRedisApi(ReplyWithDouble)
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
     GetRedisApi(CallReplyStringPtr)
     GetRedisApi(CallReplyArrayElement)

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

proc getValue*(argv: ptr ptr String,pos:cint):cstring = 
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
        
#String Commands Wrappers
proc dispatch_reply_method(reply: ptr CallReply):auto {. inline .} =
    if not reply.isNil:
       result = case CallReplyType(reply):
            of 0,1: $CallReplyStringPtr(reply,nil)
            of 2: $CallReplyInteger(reply)
            else: "-1"

proc set*(ctx: ptr Ctx, key:string, value: string, options: Table[string,string] = initTable[string,string]()) {. inline .} = 
    if options.len == 0:
        discard Call(ctx,"SET","cc",key,value)
    else:
        if options.contains("EX"):
            discard Call(ctx,"SET","cccc",key,value,"EX",options["EX"])
        elif options.contains("NX"):
            discard Call(ctx,"SET","ccc",key,value,"NX") 
        elif options.contains("XX"):
            discard Call(ctx,"SET","ccc",key,value,"XX")

proc get*(ctx: ptr Ctx, key:string):auto {. inline .} = Call(ctx,"GET","c",key).dispatch_reply_method
         
proc incr*(ctx: ptr Ctx, key:string):auto {. inline .} = Call(ctx,"INCR","c",key).dispatch_reply_method

proc incrBy*(ctx: ptr Ctx, key:string, value: string):auto {. inline .} = Call(ctx,"INCRBY","cc",key,value).dispatch_reply_method

proc decr*(ctx: ptr Ctx, key:string):auto {. inline .} = Call(ctx,"DECR","c",key).dispatch_reply_method

proc decrBy*(ctx: ptr Ctx, key:string, value: string):auto {. inline .} = Call(ctx,"DECRBY","cc",key,value).dispatch_reply_method


#Set Commands Wrappers

proc sadd*(ctx:ptr Ctx, key:string, members:seq[string]): auto {. inline .} = 
    for member in members: discard Call(ctx,"SADD","cc",key,member)

proc sremove*(ctx:ptr Ctx, key:string, members: seq[string]): auto {. inline .} =
    for member in members: discard Call(ctx,"SREM","cc",key,member)

proc scard*(ctx:ptr Ctx, key:string): auto {. inline .} = Call(ctx,"SCARD","c",key).dispatch_reply_method

proc sdiffstore*(ctx:ptr Ctx, keys:seq[string]): auto {. inline .} = 
    Call(ctx,"SDIFF","ccc",keys[0],keys[1],keys[2]).dispatch_reply_method

proc smove*(ctx:ptr Ctx, keys:seq[string]): auto {. inline .} =
    Call(ctx,"SMOVE","ccc",keys[0],keys[1],keys[2]).dispatch_reply_method

proc sinterstore*(ctx:ptr Ctx, keys:seq[string]): auto {. inline .} =
    Call(ctx,"SINTERSTORE","ccc",keys[0],keys[1],keys[2]).dispatch_reply_method

proc sunionstore*(ctx:ptr Ctx, keys:seq[string]): auto {. inline .} =
    Call(ctx,"SUNIONSTORE","ccc",keys[0],keys[1],keys[2]).dispatch_reply_method

proc sismember*(ctx:ptr Ctx, key: string, value:string): auto {. inline .} =
    Call(ctx,"SISMEMBER","cc",key,value).dispatch_reply_method

proc dispatch_array_reply(reply: ptr CallReply):auto {. inline .} =
    var r: seq[string]
    if not reply.isNil:
       var ugly_arr = CallReplyArrayElement(reply,0).dispatch_reply_method.split("\c\n")
       for u in ugly_arr: 
           if not u.split("\c\n")[0].contains("$"):
               r.add(u.split("\c\n")[0])
    result = r[0..r.len-2]

proc smembers*(ctx:ptr Ctx, key:string): auto {. inline .} = 
    Call(ctx,"SMEMBERS","c",key).dispatch_array_reply

proc sdiff*(ctx:ptr Ctx, keys:seq[string]): auto {. inline .} = 
    Call(ctx,"SDIFF","cc",keys[0],keys[1]).dispatch_array_reply

proc sinter*(ctx:ptr Ctx, keys:seq[string]): auto {. inline .} =
    Call(ctx,"SINTER","cc",keys[0],keys[1]).dispatch_array_reply

proc sunion*(ctx:ptr Ctx, keys:seq[string]): auto {. inline .} =
    Call(ctx,"SUNION","cc",keys[0],keys[1]).dispatch_array_reply

#Sorted Set Commands Wrappers


#redis macro definition
proc explainWrapper(fn: NimNode ):untyped =
     # Cambiamos el nombre de la funcion para evitar inconvenientes
     # Esta nueva funcion será la que se registre como redismodules
     # La version sin convertir funcionara para test

     let redis_proc = newProc(ident($fn.name))
     # Especificamos el return type
     redis_proc.params[0] = ident("cint")

     #NimTypes to RedisTypes
     var NimTypes = {"int": "clonglong", "double": "cdouble", "float": "cdouble", "string":"const_char_pp"}.toTable
     var ReplyWithRedisTypes = {"int":"LongLong", "double": "Double", "string":"SimpleString"}.toTable
     var RedisToNim = {"int":"getLongLong", "double": "getDouble", "string":"getValue"}.toTable

     # Especificamos los parametros para que sea una funcion compatible
     redis_proc.params.add(newIdentDefs(ident("ctx"),newEmptyNode()),
                           newIdentDefs(ident("argv"),newEmptyNode()),
                           newIdentDefs(ident("argc"),newEmptyNode()) )

     let rbody = newTree(nnkStmtList, redis_proc.body)
     let fnparams_len = fn.params.len - 1
     var varSection = newNimNode(nnkVarSection)

     # Declaramos las variables desde las especificaciones del los parametros
     for i in 1..fnparams_len:
         var param = fn.params[i].repr.split(":")
         var pvar  =  param[0]
         var ptype =  param[1].split(" ")[1]
         varSection.add( newIdentDefs(ident(pvar), ident(NimTypes[ptype])))

     #verificar si puedo cambiar esto por el implicit result
     varSection.add( newIdentDefs(ident("myres"), ident(NimTypes[fn.params[0].repr])) )
     rbody.add(varSection)

     # Como los parametros ahora son movidos de contexto al cuerpo de la funcion,
     # sus valores son extraidos desde el parametro argv
     for i in 1..fnparams_len:
         var param = fn.params[i].repr.split(":")
         var pvar  =  param[0]
         var ptype =  param[1].split(" ")[1]
         var f = RedisToNim[ptype]
         if ptype == "string":
             var getValue = newCall(ident(f),[ident("argv"),newIntLitNode(i)])
             rbody.add newNimNode(nnkAsgn).add(ident(pvar),getValue)
         else:
             rbody.add newCall(ident(f),[ident("argv"),newIntLitNode(i), newCall(ident("addr"),ident(pvar))])

     # Copiamos las operaciones de la funcion original
     let body_lines = fn.body.len - 2
     for lines in 0..body_lines: rbody.add fn.body[lines]
     rbody.add newNimNode(nnkAsgn).add(ident("myres"),fn.body[^1])
     # Especificamos el return type para redis
     var replywith = ident("ReplyWith" & ReplyWithRedisTypes[fn.params[0].repr])
     rbody.add newCall(replywith,[ident("ctx"),ident("myres")])

     # Definimos los pragmas
     let redis_pragmas = newNimNode(nnkPragma)
     redis_pragmas.add(ident("exportc"))
     redis_pragmas.add(ident("dynlib"))
     redis_proc.pragma = redis_pragmas

     redis_proc.body = rbody
     echo redis_proc.repr
     echo fn.repr
     result = redis_proc

macro redis*(fn: untyped):untyped = explainWrapper(fn)
