const date = Variable("")

function runEveryMinute(callback) {
    callback();
    const now = new Date();
    console.log(now);

    let delay = 60000 - (now.getSeconds() * 1000 + now.getMilliseconds());

    setTimeout(
        () => { runEveryMinute(callback); },
         delay
    );
}

runEveryMinute(async () => {
    date.setValue(await Utils.execAsync('date "+%c"'));
});

export function Clock() {
    return Widget.Label({
        class_name: "clock",
        label: date.bind(),
    })
}
