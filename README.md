# 閲覧数の確認 Qiita API
Copyright (c) 2022 Michio Inoue.

Qiita に投稿されている特定のアカウントの記事の一覧を Qiita API で取得し、
一定期間中の閲覧数順に並べたものを、Qiita の記事として自動更新するスクリプト。
GitHub Actions で月末に定期実行させます。

閲覧数（view 数）は自分の投稿であれば取得できるようなので、この例では
は [@eigs](https://qiita.com/eigs) の投稿を対象にしており、結果は
[これまで投稿まとめ：閲覧数順一覧](https://qiita.com/eigs/items/ce39353181fee616d52e)
で確認できます。

## 作成環境

 - MATLAB R2022a

## Acknowledgement

- [kikd/matlab-post-qiita](https://github.com/kikd/matlab-post-qiita)
- [MATLABでQiitaへ記事を投稿してみた](https://qiita.com/kikd/items/5196b3a46e291a3666fc) by [@kikd](https://qiita.com/kikd) さん