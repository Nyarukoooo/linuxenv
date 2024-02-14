## CCP: 终端上的加密货币价格查询工具

**简介**

CCP 是一款用于查询加密货币实时价格的终端命令行工具，它使用 CoinMarketCap API 获取数据。

**使用前准备**

1. 确保您的设备能够连接到互联网并可以访问 CoinMarketCap.com。您可以通过在终端输入 `ping coinmarketcap.com` 来检查连接是否正常。
2. 确保您的设备已安装 PostgreSQL 数据库。您可以通过输入 `psql --version` 来查看当前 PostgreSQL 版本。

**功能描述**

| 命令 | 功能 |
|---|---|
| `ccp` | 显示当前观察列表中所有加密货币的价格信息 |
| `ccp <tokens>` | 仅查询加密货币价格信息 |
| `ccp -s <tokens>` | 创建新的观察列表并显示指定加密货币的价格信息 |
| `ccp -a <tokens>` | 将指定加密货币添加到观察列表中 |
| `ccp -d <tokens>` | 从观察列表中删除指定加密货币 |
| `ccp -h` | 显示帮助信息 |

**示例**

* 创建一个包含 BTC、ETH 和 BNB 的观察列表并显示价格信息:

```
ccp -s BTC ETH BNB
```

* 显示当前观察列表中所有加密货币的价格信息:

```
ccp
```
* 显示BTC, ETH和BNB的当前价格信息:

```
ccp BTC ETH BNB
```

* 将 ADA 和 DOT 添加到观察列表中:

```
ccp -a ADA DOT
```

* 从观察列表中删除 XRP:

```
ccp -d XRP
```

* 显示帮助信息:

```
ccp -h
```


**选项**

* `-s <tokens>`: 指定要观察的加密货币（以逗号分隔）。
* `-a <tokens>`: 将加密货币添加到观察列表中。
* `-d <tokens>`: 从观察列表中删除加密货币。
* `-h`: 显示帮助信息。

**注意**

* 首次使用 CCP 时，需要创建一个配置文件。该配置文件将存储您的观察列表和其他设置。
* CCP 使用 PostgreSQL 数据库存储数据。默认情况下，数据库将存储在 `~/.ccp/ccp.db` 文件中。

**反馈**

如果您有任何问题或建议，请随时在 GitHub 上提交 issue 或 pull request。

