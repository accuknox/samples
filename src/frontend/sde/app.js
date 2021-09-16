(function() {
  const APP_KEY = 'PUSHER_APP_KEY';
  const APP_CLUSTER = 'eu';

  const logsDiv = document.getElementById('logs');

  const pusher = new Pusher(APP_KEY, {
    cluster: APP_CLUSTER,
  });

  const channel = pusher.subscribe('realtime-terminal');

  channel.bind('logs', data => {
    const divElement = document.createElement('div');
    divElement.innerHTML = data;

    logsDiv.appendChild(divElement);
  });
})();
