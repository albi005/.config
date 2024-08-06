const date = Variable("")

// no time to waste
function runEveryMinute(callback) {
    callback();

    const now = new Date();
    const delay = 60000 - (now.getSeconds() * 1000 + now.getMilliseconds());

    setTimeout(() => {
        callback();
        setInterval(callback, 60000);
    }, delay);
}

runEveryMinute(async () => {
    date.setValue(await Utils.execAsync('date "+%Y.%m.%d  %R"'));
});

export function Clock() {
    return Widget.Label({
        class_name: "clock",
        label: date.bind(),
    })
}
