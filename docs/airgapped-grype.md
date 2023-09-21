# Airgapped Grype Usage

TAP supports the use of Grype in airgapped environments. In order to to do this:
* download at least one Grype database file
* create a `listing.json`
* Host both files on an HTTP endpoint accessible to TAP
* configure `grype.db.dbUpdateUrl` in `tap-values.yml` (this repo has a section for this already).

See below for a short script that downloads the databases and generates the `listing.json` for you.

NOTE: TAP requires version `5` of Grype databases in order to succeed.

## Example listing.json

```json
{
  "available": {
    "5": [
      {
        "built": "2023-04-14T01:31:55Z",
        "version": 5,
        "url": "some-silly-server.com/db/vulnerability-db_v5_2023-04-14T01:31:55Z_6b256bac7e9f9cd04966.tar.gz",
        "checksum": "sha256:96c8bc71a9d9ff395356793de526d43353566b7beb59a2ab77de2849bbeadda0"
      }
    ]
  }
}
```

## Downloading files and creating the listing.json

Run this script to download the latest 5 databases from Grype. It takes a single argument: the hostname where you are hosting your databases.

For example:

```sh
./download_grype_dbs https://some-silly-server.com
```

```sh
# download_grype_dbs.sh
ESCAPED_1=$(sed 's/[\*\/]/\\&/g' <<<"$1")
wget https://toolbox-data.anchore.io/grype/databases/listing.json
jq --arg v1 "$v1" '{ "available": { "1" : [.available."1"[0]] , "2" : [.available."2"[0]], "3" : [.available."3"[0]] , "4" : [.available."4"[0]] , "5" : [.available."5"[0]] } }' listing.json > listing.json.tmp
mv listing.json.tmp listing.json
wget $(cat listing.json |jq -r '.available."1"[0].url')
wget $(cat listing.json |jq -r '.available."2"[0].url')
wget $(cat listing.json |jq -r '.available."3"[0].url')
wget $(cat listing.json |jq -r '.available."4"[0].url')
wget $(cat listing.json |jq -r '.available."5"[0].url')
sed -i -e "s/https:\/\/toolbox-data.anchore.io\/grype\/databases/$ESCAPED_1/g" listing.json
```

The script will also generate your `listing.json` with the correct hostname.

## Deploying TAP Overlay for Grype
Grype's default behavior is to fail if the db file used is more than 5 days old. 
Grype's default behavior also includes checking for the latest version of the CLI, which will fail when there's no Internet.

You can change this behavior via an overlay for your tap-values file. This repo has all the files necessary to do this.

### Deploy the overlay secret
There is a secret in [the additional/grype](../additional/grype/) directory that contains the updated config. Change the value to suit your needs and apply it with `kubectl apply`.

### Apply overlay to tap-values and namespace provisioner
In [tap-values-templated.yml](../tap-values-templated.yml), there is a commented-out section that will apply the overlay to the grype package in TAP. Uncomment that section.
In your `tap-install-config.yml`, there is a commented section under `namespace-provisioner` for applying overlays. Uncomment that section.

### Apply changes.
Re-run [install-tap.sh](../install-tap.sh) to apply your changes. This should update the Grype package to provide the necessary environment variables to change Grype's behavior.