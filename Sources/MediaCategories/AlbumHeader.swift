/*****************************************************************************
 * AlbumHeader.swift
 *
 * Copyright © 2022 VLC authors and VideoLAN
 *
 * Authors: Diogo Simao Marques <diogo.simaomarquespro@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class AlbumHeaderLayout: UICollectionViewFlowLayout {
    // Zoom on the thumbnail when scrolling up
    // Whithout dragging the image down
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let layoutAttributes = super.layoutAttributesForElements(in: rect)

        layoutAttributes?.forEach({ (attributes) in
            if attributes.representedElementKind == UICollectionView.elementKindSectionHeader {
                guard let collectionView = collectionView else { return }

                let contentOffsetY = collectionView.contentOffset.y

                if contentOffsetY > 0 {
                    return
                }

                let width = attributes.frame.width
                let height = attributes.frame.height - contentOffsetY
                attributes.frame = CGRect(x: 0, y: contentOffsetY, width: width, height: height)
            }
        })

        return layoutAttributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    func getHeaderSize(with width: CGFloat) -> CGSize {
        let isLandscape: Bool = UIDevice.current.orientation.isLandscape
        let headerHeight: CGFloat = isLandscape ? 250.0 : 350.0

        return CGSize(width: width, height: headerHeight)
    }
}

class AlbumHeader: UICollectionReusableView {
    // MARK: - Properties

    static var headerID = "headerID"

    private weak var parentView: UIView?

    private var imageView = UIImageView()

    private var titleLabel = UILabel()

    var collection: VLCMLObject?

    private var playAllButton = UIButton(type: .custom)

    private var playShuffleButton = UIButton(type: .custom)

    private var layoutGuide: UILayoutGuide?

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = PresentationTheme.current.colors.background
        setupImageView()
        setupTitleLabel()
        setupPlayAllButton()
        setupShuffleButton()
        setupConstraints()
        updateUserInterfaceStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private methods

    private func setupImageView() {
        addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
    }

    private func setupTitleLabel() {
        addSubview(titleLabel)
        // The text color should be light colored in order to be visible on top of
        // the image with the dark gradient.
        titleLabel.textColor = PresentationTheme.darkTheme.colors.cellTextColor
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title3).bolded
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupPlayAllButton() {
        addSubview(playAllButton)
        let buttonSize: CGFloat = 50.0
        playAllButton.tag = 0
        playAllButton.translatesAutoresizingMaskIntoConstraints = false
        playAllButton.setImage(UIImage(named: "iconPlay")?.withRenderingMode(.alwaysTemplate), for: .normal)
        playAllButton.layer.cornerRadius = 0.5 * buttonSize
        playAllButton.clipsToBounds = true
        playAllButton.tintColor = .white
        playAllButton.backgroundColor = PresentationTheme.current.colors.orangeUI
        playAllButton.addTarget(self, action: #selector(handlePlayAll(sender:)), for: .touchUpInside)
    }

    private func setupShuffleButton() {
        addSubview(playShuffleButton)
        let buttonSize: CGFloat = 50.0
        playShuffleButton.tag = 1
        playShuffleButton.translatesAutoresizingMaskIntoConstraints = false
        playShuffleButton.setImage(UIImage(named: "shuffle"), for: .normal)
        playShuffleButton.layer.cornerRadius = 0.5 * buttonSize
        playShuffleButton.clipsToBounds = true
        playShuffleButton.tintColor = .white
        playShuffleButton.backgroundColor = PresentationTheme.current.colors.orangeUI
        playShuffleButton.addTarget(self, action: #selector(handlePlayAllShuffle(sender:)), for: .touchUpInside)
    }

    private func setupConstraints() {
        let buttonSize: CGFloat = 50.0
        let playShuffleTrailingAnchor: NSLayoutConstraint
        if let parentView = parentView, #available(iOS 11.0, *) {
            playShuffleTrailingAnchor = playShuffleButton.trailingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        } else {
            playShuffleTrailingAnchor = playShuffleButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        }

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 20),
            titleLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -10),

            playAllButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 10),
            playAllButton.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -10),
            playAllButton.heightAnchor.constraint(equalToConstant: buttonSize),
            playAllButton.widthAnchor.constraint(equalTo: playAllButton.heightAnchor),

            titleLabel.centerYAnchor.constraint(equalTo: playAllButton.centerYAnchor),

            playShuffleButton.leadingAnchor.constraint(equalTo: playAllButton.trailingAnchor, constant: 10),
            playShuffleButton.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -10),
            playShuffleTrailingAnchor,
            playShuffleButton.heightAnchor.constraint(equalToConstant: buttonSize),
            playShuffleButton.widthAnchor.constraint(equalTo: playShuffleButton.heightAnchor),
            playShuffleButton.centerYAnchor.constraint(equalTo: playAllButton.centerYAnchor)
        ])
    }

    private func imageWithGradient(img: UIImage) -> UIImage {
        UIGraphicsBeginImageContext(img.size)
        let context = UIGraphicsGetCurrentContext()

        img.draw(at: CGPoint(x: 0, y: 0))

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let loc: [CGFloat] = [0.0, 0.65, 1.0]

        let top = UIColor.black.cgColor
        let middle = UIColor.clear.cgColor
        let bottom = UIColor.black.cgColor

        let colors = [top, middle, bottom] as CFArray

        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: loc)

        let startPoint = CGPoint(x: img.size.width/2, y: 0)
        let endPoint = CGPoint(x: img.size.width/2, y: img.size.height)

        guard let context = context,
              let gradient = gradient else {
            UIGraphicsEndImageContext()
            return img
        }

        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: UInt32(0)))

        let image = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        guard let image = image else {
            return img
        }

        return image
    }

    private func playAll(shuffle: Bool) {
        if let album = collection as? VLCMLAlbum {
            let playbackService = PlaybackService.sharedInstance()
            playbackService.playCollection(album.tracks)
            playbackService.isShuffleMode = shuffle
        }
    }

    // MARK: - Methods

    func updateImage(with image: UIImage?) {
        guard let image = image else {
            return
        }

        let img = imageWithGradient(img: image)
        imageView.image = img
    }

    func updateThumbnailTitle(_ title: String) {
        titleLabel.text = title
    }

    func shouldDisablePlayButtons(_ disable: Bool) {
        playAllButton.isEnabled = !disable
        playShuffleButton.isEnabled = !disable
    }

    func updateParentView(parent: UIView) {
        parentView = parent
        removeConstraints(self.constraints)
        setupConstraints()
    }

    func updateUserInterfaceStyle(isStatusBarVisible: Bool = false) {
        guard #available(iOS 13.0, *), !PresentationTheme.current.isDark else {
            return
        }

        let currentTheme = !isStatusBarVisible ? PresentationTheme.darkTheme : PresentationTheme.current
        AppearanceManager.setupUserInterfaceStyle(theme: currentTheme)
    }

    // MARK: - Actions

    @objc func handlePlayAll(sender: UIButton) {
        playAll(shuffle: false)
    }

    @objc func handlePlayAllShuffle(sender: UIButton) {
        playAll(shuffle: true)
    }
}
