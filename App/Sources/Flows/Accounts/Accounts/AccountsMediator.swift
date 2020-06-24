import UIKit

protocol AccountsMediator: AnyObject {}

final class AccountsMediatorImpl: NSObject, AccountsMediator {
    private let viewModel: AccountsViewModel
    private let collectionView: UICollectionView

    init(collectionView: UICollectionView, viewModel: AccountsViewModel) {
        self.collectionView = collectionView
        self.viewModel = viewModel

        super.init()

        collectionView.register(R.nib.accountCell)

        collectionView.dataSource = self
        collectionView.delegate = self

        viewModel.onDataSourceChange = { [weak self] in
            DispatchQueue.main.async {
                self?.collectionView.reloadData()
            }
        }
    }
}

extension AccountsMediatorImpl: UICollectionViewDataSource {
    func numberOfSections(in _: UICollectionView) -> Int {
        viewModel.numberOfSections()
    }

    func collectionView(_: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        viewModel.numberOfItems(in: section)
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.account_cell, for: indexPath)!

        let cellModel = viewModel.cellModelForItem(at: indexPath)
        cell.setup(model: cellModel)
        return cell
    }
}

extension AccountsMediatorImpl: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout _: UICollectionViewLayout,
                        sizeForItemAt _: IndexPath) -> CGSize {
        CGSize(width: collectionView.bounds.width - 30.0, height: 100)
    }

    func collectionView(_: UICollectionView,
                        layout _: UICollectionViewLayout,
                        insetForSectionAt _: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0.0, left: 15.0, bottom: 0.0, right: 15.0)
    }
}