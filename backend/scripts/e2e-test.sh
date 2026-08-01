#!/bin/bash
# E2E test of every DB-writing Nexora API endpoint against a live backend.
# Assumes the backend is running on localhost:4000 and MongoDB is reachable.
BASE=http://localhost:4000/api/v1
pass=0
fail=0
STAMP=$(date +%s)
EMAIL="e2e$STAMP@nexora.test"

check() {
  if [ "$2" = "$3" ]; then
    pass=$((pass+1)); echo "PASS: $1"
  else
    fail=$((fail+1)); echo "FAIL: $1 (got: $2, want: $3)"
  fi
}

extract() { python -c "import sys,json; d=json.load(sys.stdin); print(d.get('$1',''))" 2>/dev/null; }
extract_user() { python -c "
import sys,json
d=json.load(sys.stdin)
user=d.get('user',{})
print(user.get('$1',''))
" 2>/dev/null; }

echo "── 1. Register ───────────────────────────────────────────"
R=$(curl -s -X POST $BASE/auth/register -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"e2epass123\",\"name\":\"E2E Tester\",\"username\":\"e2et$STAMP\"}")
TOKEN=$(echo "$R" | extract token)
REFRESH=$(echo "$R" | extract refreshToken)
check "register returns token" "$([ -n "$TOKEN" ] && echo yes)" "yes"

echo "── 2. Login ──────────────────────────────────────────────"
R=$(curl -s -X POST $BASE/auth/login -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"e2epass123\"}")
TOKEN=$(echo "$R" | extract token)
REFRESH=$(echo "$R" | extract refreshToken)
check "login returns token" "$([ -n "$TOKEN" ] && echo yes)" "yes"
USER_ID=$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin)['user']['id'])")
echo "user id: $USER_ID"

AUTH="Authorization: Bearer $TOKEN"

echo "── 3. Me ─────────────────────────────────────────────────"
R=$(curl -s $BASE/auth/me -H "$AUTH")
check "me returns user" "$(echo "$R" | extract_user id)" "$USER_ID"

echo "── 4. Update profile ─────────────────────────────────────"
R=$(curl -s -X PATCH $BASE/auth/me -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"bio":"E2E tester bio","location":"Testville"}')
check "profile updated" "$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin)['user']['bio'])")" "E2E tester bio"

echo "── 5. Create post ────────────────────────────────────────"
R=$(curl -s -X POST $BASE/posts -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"caption":"E2E test post caption","hashtags":["e2e","test"]}')
POST_ID=$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin)['post']['id'])" 2>/dev/null)
check "post created" "$([ -n "$POST_ID" ] && echo yes)" "yes"
echo "post id: $POST_ID"

echo "── 6. Get post ───────────────────────────────────────────"
R=$(curl -s $BASE/posts/$POST_ID -H "$AUTH")
check "get post" "$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin)['post']['caption'])")" "E2E test post caption"

echo "── 7. Comment on post ────────────────────────────────────"
R=$(curl -s -X POST $BASE/posts/$POST_ID/comments -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"text":"E2E comment"}')
check "comment created" "$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin)['comment']['text'])")" "E2E comment"

echo "── 8. Like post ──────────────────────────────────────────"
R=$(curl -s -X POST $BASE/posts/$POST_ID/like -H "$AUTH")
check "like ok" "$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin)['liked'])")" "True"

echo "── 9. Bookmark post ──────────────────────────────────────"
R=$(curl -s -X POST $BASE/posts/$POST_ID/bookmark -H "$AUTH")
check "bookmark ok" "$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin)['bookmarked'])")" "True"

echo "── 10. Feed includes post ────────────────────────────────"
R=$(curl -s "$BASE/feed?page=1&limit=50" -H "$AUTH")
check "feed works" "$([ -n "$(echo "$R" | extract data)" ] && echo yes)" "yes"

echo "── 11. Find aria via search ──────────────────────────────"
R=$(curl -s "$BASE/users/search?q=ariachen" -H "$AUTH")
ARIA=$(echo "$R" | python -c "
import sys,json
d=json.load(sys.stdin)
for u in d.get('data',{}).get('people',[]):
    if u.get('username')=='ariachen': print(u.get('id'))
" 2>/dev/null)
check "aria found" "$([ -n "$ARIA" ] && echo yes)" "yes"

echo "── 12. Follow aria ───────────────────────────────────────"
R=$(curl -s -X POST $BASE/users/$ARIA/follow -H "$AUTH" -H 'Content-Type: application/json' -d '{}')
check "follow ok" "$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin).get('following',''))")" "True"

echo "── 13. Start conversation with aria ──────────────────────"
R=$(curl -s -X POST $BASE/chat -H "$AUTH" -H 'Content-Type: application/json' -d "{\"userId\":\"$ARIA\"}")
CONVO=$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin).get('conversationId',''))" 2>/dev/null)
check "conversation started" "$([ -n "$CONVO" ] && echo yes)" "yes"

echo "── 14. Send message ──────────────────────────────────────"
R=$(curl -s -X POST $BASE/chat/$CONVO/messages -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"text":"Hello from E2E"}')
check "message sent" "$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin)['message']['text'])")" "Hello from E2E"

echo "── 15. List conversations ────────────────────────────────"
R=$(curl -s $BASE/chat -H "$AUTH")
check "conversations listed" "$([ -n "$(echo "$R" | extract data)" ] && echo yes)" "yes"

echo "── 16. Report post ───────────────────────────────────────"
R=$(curl -s -X POST $BASE/reports -H "$AUTH" -H 'Content-Type: application/json' \
  -d "{\"targetType\":\"post\",\"targetId\":\"$POST_ID\",\"reason\":\"spam\",\"details\":\"E2E report\"}")
check "report created" "$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin)['report']['reason'])")" "spam"

echo "── 17. Refresh token ─────────────────────────────────────"
R=$(curl -s -X POST $BASE/auth/refresh -H 'Content-Type: application/json' \
  -d "{\"refreshToken\":\"$REFRESH\"}")
NEW_TOKEN=$(echo "$R" | extract token)
check "refresh returns new token" "$([ -n "$NEW_TOKEN" ] && echo yes)" "yes"

echo "── 18. Stories list ──────────────────────────────────────"
R=$(curl -s "$BASE/feed/stories" -H "$AUTH")
check "stories works" "$(echo "$R" | python -c "import sys,json; d=json.load(sys.stdin); print('ok' if 'data' in d else 'missing')")" "ok"

echo "── 19. Logout ────────────────────────────────────────────"
R=$(curl -s -X POST $BASE/auth/logout -H "$AUTH" -H 'Content-Type: application/json' -d '{}')
check "logout ok" "$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin).get('ok'))")" "True"

echo ""
echo "══════════════════════════════════════════════════════"
echo "RESULT: $pass passed, $fail failed"
exit $fail
