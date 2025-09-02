window.addEventListener("message", function (event) {
    const data = event.data;
    if (data.action === "loadInbox") {
        renderInbox(data.messages, data.pigeonId);
    } else if (data.action === "open") {
        document.body.style.display = "block";
        document.getElementById("ui").style.display = "block";
        showTab("inbox");
    } else if (data.action === "hide") {
        document.body.style.display = "none";
        document.getElementById("ui").style.display = "none";
        console.log("DEBUG JS: Received zones from client:", data.zones);
    } else if (data.action === "displayTrainedZones") {
        renderTrainedZones(data.zones || []);
    }
});

function showTab(tabName) {
    document.getElementById("sendTab").style.display = tabName === "send" ? "block" : "none";
    document.getElementById("inboxTab").style.display = tabName === "inbox" ? "block" : "none";
    document.getElementById("trainTab").style.display = tabName === "train" ? "block" : "none";
}

function sendMessage() {
    const target = document.getElementById("targetId").value;
    const message = document.getElementById("messageContent").value;

    if (!target || !message) {
        alert("You must provide both a recipient ID and a message.");
        return;
    }

    fetch(`https://${GetParentResourceName()}/sendMessage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ target, message })
    });

    document.getElementById("messageContent").value = "";
    document.getElementById("targetId").value = "";
    closeUI();
}

function closeUI() {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function deleteMessage(id) {
    fetch(`https://${GetParentResourceName()}/deleteMessage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id })
    }).then(() => {
        fetch(`https://${GetParentResourceName()}/refreshInbox`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    });
}

function renderInbox(messages, pigeonId) {
    const inboxList = document.getElementById("inboxList");
    inboxList.innerHTML = "";

    document.getElementById("pigeonIdDisplay").innerText = `Your Pigeon ID: ${pigeonId}`;

    if (!messages || messages.length === 0) {
        inboxList.innerHTML = "<p class='empty'>Your pigeon has returned with no messages.</p>";
        return;
    }

    messages.forEach(msg => {
        const msgElem = document.createElement("div");
        msgElem.className = "message";

        msgElem.innerHTML = `
            <strong>From:</strong> ${msg.sender_pigeon_uid}<br>
            <strong>Message:</strong> ${msg.message}<br>
            <button onclick="deleteMessage(${msg.id})">🗑️ Burn Message</button>
        `;

        inboxList.appendChild(msgElem);
    });
}

function trainPigeon() {
    const locationName = document.getElementById("locationName").value.trim();
    if (!locationName) {
        alert("You must enter a location name.");
        return;
    }

    fetch(`https://${GetParentResourceName()}/trainPigeon`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ locationName })
    });

    document.getElementById("locationName").value = "";
}

function getTrainedZones() {
    console.log("DEBUG: Fetching trained zones from server...");
    fetch(`https://${GetParentResourceName()}/getTrainedZones`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}


function renderTrainedZones(zones) {
    const container = document.getElementById("trainedZones");
    container.innerHTML = "";

    if (zones.length === 0) {
        container.innerHTML = "<p class='empty'>No trained locations yet.</p>";
        return;
    }

    zones.forEach(zone => {
        const elem = document.createElement("div");
        elem.className = "message";
        elem.innerHTML = `
            <strong>📍 ${zone.location_name}</strong><br>
            <em>X:</em> ${zone.coords_x.toFixed(2)} / <em>Y:</em> ${zone.coords_y.toFixed(2)}
            <br>
            <button onclick="showZoneBlip(${zone.coords_x}, ${zone.coords_y}, ${zone.coords_z}, '${zone.location_name}')">📌 Show Zone</button>
        `;
        container.appendChild(elem);
    });
}

function showZoneBlip(x, y, z, name) {
    console.log("[DEBUG] showZoneBlip called:", x, y, z, name); // this should show in F8/NUI console
    const decodedName = decodeURIComponent(name);

    fetch(`https://${GetParentResourceName()}/showZone`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ x, y, z, name: decodedName })
    });
}



function showAllTrainedZones() {
    fetch(`https://${GetParentResourceName()}/showAllZones`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

