const Zoom = require('ti.zoomtransition');

const rootWindow = Ti.UI.createWindow({
  backgroundColor: '#f5f4f8',
  title: 'Zoom Transition'
});

const sourceView = Ti.UI.createView({
  top: 110,
  width: 190,
  height: 190,
  borderRadius: 22,
  backgroundColor: '#6757d9'
});

sourceView.add(Ti.UI.createLabel({
  text: 'ALBUM',
  color: '#ffffff',
  font: { fontSize: 24, fontWeight: 'bold' }
}));

rootWindow.add(sourceView);
rootWindow.add(Ti.UI.createLabel({
  top: 325,
  left: 24,
  right: 24,
  textAlign: Ti.UI.TEXT_ALIGNMENT_CENTER,
  color: '#24232a',
  text: Zoom.isSupported()
    ? 'Tap the album. Pull down while the table is at the top, or directly drag the full-screen detail to dismiss.'
    : 'This example requires iOS 18 or later.'
}));

function openAlbum() {
  if (!Zoom.isSupported()) {
    return;
  }

  const detailWindow = Ti.UI.createWindow({
    backgroundColor: '#11131a',
    modal: true,
    modalStyle: Ti.UI.iOS.MODAL_PRESENTATION_FULLSCREEN,
    navBarHidden: true
  });

  const headerView = Ti.UI.createView({
    height: 430,
    backgroundColor: '#11131a'
  });

  const artwork = Ti.UI.createView({
    top: 54,
    width: 260,
    height: 260,
    borderRadius: 28,
    backgroundColor: '#6757d9'
  });

  artwork.add(Ti.UI.createLabel({
    text: 'ALBUM',
    color: '#ffffff',
    font: { fontSize: 32, fontWeight: 'bold' }
  }));

  const closeButton = Ti.UI.createButton({
    top: 326,
    width: 120,
    height: 44,
    title: 'Close'
  });

  headerView.add(artwork);
  headerView.add(closeButton);

  const rows = Array.from({ length: 24 }, (_, index) => Ti.UI.createTableViewRow({
    height: 58,
    title: `${index + 1}. Example Track`,
    color: '#ffffff',
    backgroundColor: '#171a23'
  }));

  const tableView = Ti.UI.createTableView({
    backgroundColor: '#11131a',
    separatorColor: '#343743',
    headerView,
    data: rows
  });

  detailWindow.add(tableView);

  Zoom.prepareWindow(detailWindow, {
    sourceView,
    scrollView: tableView,
    fullScreen: true,
    interactiveDismiss: true,
    onlyWhenScrollAtTop: true
  });

  const closeDetail = () => detailWindow.close({ animated: true });
  closeButton.addEventListener('click', closeDetail);

  detailWindow.addEventListener('close', () => {
    closeButton.removeEventListener('click', closeDetail);
    Zoom.clearWindow(detailWindow);
  });

  detailWindow.open({ animated: true });
}

sourceView.addEventListener('click', openAlbum);
rootWindow.open();
