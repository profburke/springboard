#ifndef sb_ios2lua_h
#define sb_ios2lua_h

#define nodeType(X) plist_get_node_type(X)
#define dictEntry(D, K) plist_dict_get_item(D, K)
#define arrayElem(A, I) plist_array_get_item(A, I)
#define stringVal(N, V) plist_get_string_val(N, V)
#define getBool(N, B) plist_get_bool_val(N, B)
#define groupSize(X) plist_array_get_size(X)
#define dictSize(X) plist_dict_get_size(X)

void parseNode(lua_State* L, plist_t node, int depth, int handleIdx);
char *getStringVal(plist_t dict, const char* key);
void flatPackArray(lua_State* L, plist_t node, int depth, int handleIdx);

#define SET_STRING(L,K,V) lua_pushstring(L,V); lua_setfield(L,-2,K)

#endif
