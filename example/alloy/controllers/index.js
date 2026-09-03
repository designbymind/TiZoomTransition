const isLightMode = Ti.UI.userInterfaceStyle === 1;
const rootBackgroundColor = isLightMode ? '#FFFFFF' : '#000000';

let activeZoomController = null;

const randomImageCategories = [
	'Nature', 'Office', 'People', 'Technology', 'Minimal', 'Abstract', 'Aerial',
	'Blurred', 'Bokeh', 'Gradient', 'Monochrome', 'Vintage', 'White', 'Black',
	'Blue', 'Red', 'Green', 'Yellow', 'Cityscape', 'Workspace', 'Food', 'Travel',
	'Textures', 'Industry', 'Indoor', 'Outdoor', 'Studio', 'Finance', 'Medical',
	'Season', 'Holiday', 'Event', 'Sport', 'Science', 'Legal', 'Estate',
	'Restaurant', 'Retail', 'Wellness', 'Agriculture', 'Construction', 'Craft',
	'Cosmetic', 'Automotive', 'Gaming', 'Education'
];

Ti.API.info('User Interface Style: ' + Ti.UI.userInterfaceStyle);
Ti.UI.backgroundColor = rootBackgroundColor;

$.rootNavigationWindow.backgroundColor = rootBackgroundColor;
$.rootTableView.backgroundColor = rootBackgroundColor;
$.rootRightNavButton.image = Ti.UI.iOS.systemImage(
	'figure.stand.and.figure.teen',
	{ weight: 'semibold', size: 22 }
);

$.rootTableView.setData(
	Array.from({ length: 15 }, function (_value, index) {
		const row = Ti.UI.createTableViewRow({
			font: { fontSize: 32, fontWeight: 'bold' },
			textAlign: Ti.UI.TEXT_ALIGNMENT_CENTER,
			backgroundColor: rootBackgroundColor,
			color: isLightMode ? '#000000' : '#FFFFFF',
			selectedColor: isLightMode ? '#FFFFFF' : '#000000',
			selectionStyle: Ti.UI.SELECTION_STYLE_NONE
		});

		const sourceView = Ti.UI.createView({
			width: Ti.UI.FILL,
			height: 204,
			touchEnabled: false
		});

		const category = randomImageCategories[
			Math.floor(Math.random() * randomImageCategories.length)
		];
		const photoURL = 'https://static.photos/' + category.toLowerCase() + '/1024x576/';

		sourceView.add(
			Ti.UI.createImageView({
				width: 342,
				height: 192,
				top: 12,
				preventDefaultImage: true,
				image: photoURL,
				cache: false,
				borderRadius: 22
			})
		);

		row.add(sourceView);
		return row;
	})
);

function openZoomWindow(event) {
	if (activeZoomController) {
		return;
	}

	const sourceView = event.row.children[0];
	const photoURL = sourceView.children[0].image;

	activeZoomController = Alloy.createController('zoomWindow', {
		sourceView: sourceView,
		photoURL: photoURL
	});

	activeZoomController.once('closed', function () {
		activeZoomController = null;
	});

	activeZoomController.open();
}

$.rootNavigationWindow.open();
