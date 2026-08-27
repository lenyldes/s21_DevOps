#!/bin/bash

run_test() {
    local ARG=$1
    local EXPECTED=$2

    local RESULT=$(./DO "$ARG")

    if [ "$RESULT" == "$EXPECTED" ]; then
        echo "✅ Тест с аргументом '$ARG' ПРОЙДЕН!"
    else
        echo "❌ Тест с аргументом '$ARG' ПРОВАЛЕН!"
        echo "Ожидалось: '$EXPECTED', получено '$RESULT'"
        exit 1
    fi
}

run_test "1" "Learning to Linux"
run_test "2" "Learning to work with Network"
run_test "3" "Learning to Monitoring"
run_test "4" "Learning to extra Monitoring"
run_test "5" "Learning to Docker"
run_test "6" "Learning to CI/CD"
run_test "7" "Bad number!"
run_test "0" "Bad number!"

RESULT_NO_ARGS=$(./DO)
    if [ "$RESULT_NO_ARGS" == "Bad number of arguments!" ]; then
        echo "✅ Тест БЕЗ аргументов ПРОЙДЕН"
    else
        echo "❌ ПРОВАЛ! Ожидалось: 'Bad number of arguments!',
  получено: '$RESULT_NO_ARGS'"
        exit 1
    fi

RESULT_THREE_ARGS=$(./DO 1 2 3)
    if [ "$RESULT_THREE_ARGS" == "Bad number of arguments!" ]; then
        echo "✅ Тест с ТРЕМЯ аргументами ПРОЙДЕН"
    else
        echo "❌ ПРОВАЛ! Ожидалось: 'Bad number of arguments!',
  получено: '$RESULT_THREE_ARGS'"
        exit 1
    fi

echo "🎉 ВСЕ ТЕСТЫ ПРОЙДЕНЫ УСПЕШНО!"
exit 0
