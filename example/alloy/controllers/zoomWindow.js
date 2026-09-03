const Zoom = require('ti.zoomtransition');
const args = $.args;
const isLightMode = Ti.UI.userInterfaceStyle === 1;
const detailBackgroundColor = isLightMode ? '#FFFFFF' : '#0b1015';

let transitionPrepared = false;

$.detailNavigationWindow.backgroundColor = detailBackgroundColor;
$.detailTableView.backgroundColor = detailBackgroundColor;
$.detailHeaderImage.image = args.photoURL;

$.detailTableView.setData(
	Array.from({ length: 20 }, function (_value, index) {
		return Ti.UI.createTableViewRow({
			title: 'Open sub-window ' + (index + 1),
			font: { fontSize: 24, fontWeight: 'bold' },
			textAlign: Ti.UI.TEXT_ALIGNMENT_CENTER,
			indentionLevel: 2,
			backgroundColor: detailBackgroundColor,
			color: isLightMode ? '#000000' : '#FFFFFF',
			backgroundSelectedColor: isLightMode ? '#007AFF' : '#ffd60a',
			selectedColor: isLightMode ? '#FFFFFF' : '#000000',
			hasChild: true
		});
	})
);

function open() {
	if (!args.sourceView) {
		throw new Error('zoomWindow requires a sourceView');
	}

	if (Zoom.isSupported()) {
		Zoom.prepareWindow($.detailNavigationWindow, {
			sourceView: args.sourceView,
			scrollView: $.detailTableView,
			fullScreen: true,
			interactiveDismiss: true,
			onlyWhenScrollAtTop: true,
			scrollTopTolerance: 1
		});

		transitionPrepared = true;
	}

	$.detailNavigationWindow.open({
		modal: true,
		modalStyle: Ti.UI.iOS.MODAL_PRESENTATION_FULLSCREEN,
		animated: true
	});
}

function closeDetail() {
	$.detailNavigationWindow.close({ animated: true });
}

function openSubWindow(event) {
	const subWindow = Ti.UI.createWindow({
		title: 'Sub Window ' + (event.index + 1),
		extendSafeArea: true,
		extendEdges: [1, 4],
		backButtonTitle: ''
	});

	$.detailNavigationWindow.openWindow(subWindow, { animated: true });
}

function onDetailWindowClose() {
	if (transitionPrepared) {
		Zoom.clearWindow($.detailNavigationWindow);
		transitionPrepared = false;
	}

	$.trigger('closed');
	$.destroy();
}

exports.open = open;
