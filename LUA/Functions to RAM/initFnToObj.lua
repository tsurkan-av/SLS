-- инициализация функций в объектах кусками по 1024 символа, 256 в value и 256 в oldValue
local json = [[
local json={v="0.0.1"}
local encode
local ch1=string.char(34)
local ch2=string.char(92,34)
local t01={["\\"]="\\",[ch2]=ch2,["\b"]="b",["\f"]="f",["\n"]="n",["\r"]="r",["\t"]="t",}
local t02={["/"]="/"}
for k, v in pairs(t01) do t02[v]=k end
local function escCh(c) return "\\" .. (t01[c] or string.format("u%04x", c:byte())) end
local function eNil(val) return "null" end
local function eTab(val, stack)
local res={} stack=stack or {} stack[val]=true
if rawget(val, 1) ~= nil or next(val) == nil then
for i, v in ipairs(val) do table.insert(res, encode(v, stack)) end stack[val]=nil
return "[" .. table.concat(res, ",") .. "]"
else
for k, v in pairs(val) do table.insert(res, encode(k, stack) .. ":" .. encode(v, stack)) end
stack[val]=nil return "{" .. table.concat(res, ",") .. "}" end end
local function eStr(val) return ch1 .. val:gsub("[%z\1-\31\\\"]", escCh) .. ch1 end
local function eNum(val) return string.format("%.14g", val) end
local tFmap={["nil"]=eNil,["table"]=eTab,["string"]=eStr,["number"]=eNum,["boolean"]=tostring,}
encode=function(val, stack) local t=type(val) local f=tFmap[t] if f then return f(val, stack) end end
function json.encode(val, add_escape, round) if add_escape == true then return (encode(val):gsub(ch1,ch2)) else return (encode(val)) end end
local parse
local function crSet(...) local res={} for i=1, select("#", ...) do res[ select(i, ...) ]=true end return res end
local spCh=crSet(" ","\t","\r","\n")
local dCh=crSet(" ","\t","\r","\n","]","}",",")
local literal_map={["true"]=true,["false"]=false,["null"]=nil}
local function nxtCh(str, idx, set, negate) for i=idx, #str do if set[str:sub(i, i)] ~= negate then return i end end return #str + 1 end
local function cpToUtf8(n) local f=math.floor if n <= 0x7f then
return string.char(n) elseif n <= 0x7ff then
return string.char(f(n/64)+192,n % 64+128) elseif n<=0xffff then
return string.char(f(n/4096)+224,f(n % 4096/64)+128,n%64+128) elseif n<=0x10ffff then
return string.char(f(n/262144)+240,f(n % 262144/4096)+128,f(n % 4096/64)+128,n % 64+128) end end
local function pUesc(s) local n1=tonumber(s:sub(1,4),16) local n2=tonumber(s:sub(7,10),16) if n2 then return cpToUtf8((n1-0xd800)*0x400+(n2-0xdc00)+0x10000) else return cpToUtf8(n1) end end
local function pStr(str, i) local res="" local j=i+1 local k=j while j <= #str do local x=str:byte(j) if x < 32 then
elseif x == 92 then res=res .. str:sub(k,j-1) j=j+1 local c=str:sub(j,j) if c == "u" then local hex=str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j+1) or str:match("^%x%x%x%x", j+1) res=res .. pUesc(hex) j=j+ #hex else res=res .. t02[c] end k=j+1
elseif x == 34 then res=res .. str:sub(k,j-1) return res, j+1 end j=j+1 end end
local function pNum(str,i) local x=nxtCh(str,i,dCh) local s=str:sub(i,x-1) local n=tonumber(s) return n,x end local function pLiter(str,i) local x=nxtCh(str,i,dCh) local word=str:sub(i, x - 1) return literal_map[word], x end
local function pArr(str,i) local res={} local n=1 i=i+1
while 1 do local x i=nxtCh(str,i,spCh,true) if str:sub(i,i) == "]" then i=i+1 break end x,i=parse(str,i) res[n]=x n=n+1 i=nxtCh(str,i,spCh,true) local chr=str:sub(i,i) i=i+1 if chr == "]" then break end end return res,i end
local function pObj(str,i) local res={} i=i+1
while 1 do local key,val i=nxtCh(str,i,spCh,true) if str:sub(i,i) == "}" then i=i+1 break end
key,i=parse(str,i) i=nxtCh(str,i,spCh,true) i=nxtCh(str,i+1,spCh,true) val,i=parse(str,i) res[key]=val i=nxtCh(str,i,spCh,true) local chr=str:sub(i,i) i=i+1 if chr == "}" then break end end return res,i end
local chFuMap={[ch1]=pStr,["0"]=pNum,["1"]= pNum,["2"]=pNum,["3"]=pNum,["4"]=pNum,["5"]=pNum,["6"]=pNum,["7"]=pNum,["8"]=pNum,["9"]=pNum,["-"]=pNum,["t"]=pLiter,["f"]=pLiter,["n"]=pLiter,["["]=pArr,["{"]=pObj,}
parse=function(str,idx) local chr=str:sub(idx,idx) local f=chFuMap[chr] if f then return f(str,idx) end end
function json.decode(str,delEsc) if delEsc == true then str=str:gsub("\\","") end local res,idx=parse(str,nxtCh(str,1,spCh,true)) idx=nxtCh(str,idx,spCh,true) return res end
return (json)
]]

-- функция разбирает строку code и создает объекты с именем object. ChunkLen: размер куска, если не указывать = 256
-- !!! при 256 шлюз виснет на 2023.01.29d1
-- ест проблема с записью в obj подряд. если между записями ест print() - норм, иначе пишет только value, а oldValue мимо 
local function pushFnToObj(object, code, chunkLen)
  if not (chunkLen) then chunkLen = 256 end -- если не задан размер куска, то 256
  print('Init function ' .. object .. ': ...')
  print('Init function ' .. object .. ': code len = ' .. #code)
  print('Init function ' .. object .. ': chunk len = ' .. chunkLen)
  object = 'z'.. object
  code = code:gsub("\n"," ") -- удаляю перенос строк
  local oNum = 0
  local chunkLenX2 = chunkLen * 2
  local Obj, chunk1, chunk2, chunk1Write, chunk2Write, chunk1Len, chunk2Len
  for i = 1, #code, chunkLenX2 do
    chunk1Write = true
    chunk2Write = true
    oNum = oNum + 1
    Obj = object .. oNum
    chunk1 = i-1+chunkLen
    chunk2 = 0
    if (chunk1 <= #code) then
      chunk2 = i-1+chunkLenX2
      if (chunk2 <= #code) then
        chunk2 = i-1+chunkLenX2
        chunk1Len = chunkLen
        chunk2Len = chunkLen
        chunk1Write = true
        chunk2Write = true
      else
        chunk2 = #code - chunk1
        if (chunk2 > 0) then
          chunk1Len = chunkLen
          chunk2Len = chunk2
          chunk2 = #code
          chunk1Write = true
          chunk2Write = true
        else
          chunk1Len = chunkLen
          chunk2Len = chunk2
          chunk1Write = true
          chunk2Write = false
        end
      end
    else
      chunk1 = #code - chunk2
        if (chunk1 > 0) then
          chunk1Len = chunk1
          chunk2Len = 0
          chunk1 = #code
          chunk1Write = true
          chunk2Write = false
        else
          chunk1Write = false
          chunk2Write = false
        end
    end
    if ((chunk1Write and chunk2Write) and not (chunk1Write and chunk2Write)) then
      print('Init function ' .. object .. ': create Obj ' .. Obj .. ' with end of chunks: ' .. chunk1, chunk2)
      obj.set(Obj, code:sub(chunk2-chunk2Len+1, chunk2))
      print('Init function ' .. object .. ': write chunk 2 to ' .. Obj)
      obj.set(Obj, code:sub(chunk1-chunk1Len+1, chunk1))
      print('Init function ' .. object .. ': write chunk 1 to ' .. Obj)
    else
      print('Init function ' .. object .. ': create Obj ' .. Obj .. ' with end of chunks: ' .. chunk1, chunk2)
      obj.set(Obj, code:sub(chunk2-chunk2Len+1, chunk2))
      print('Init function ' .. object .. ': write chunk 2 to ' .. Obj)
      if (chunk2Write) then
        print('Init function ' .. object .. ': write chunk 1 to ' .. Obj)
        obj.set(Obj, code:sub(chunk1-chunk1Len+1, chunk1))
      else
        print('Init function ' .. object .. ': write "---" to ' .. Obj)
        obj.set(Obj, '---')
      end
    end
  end
  local msg = 'Init function ' .. object .. ': complete!'
  telegram.send(msg)
  print(msg)
end

pushFnToObj('Json', json, 255)
-- отключение таймера инициализации
scripts.setTimer("initFnToObj", 0, 0)
