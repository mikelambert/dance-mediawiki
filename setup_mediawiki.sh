#!/bin/bash

set -e

export MEDIAWIKI_PATH=/opt/bitnami/apps/mediawiki
export EXTENSION_PATH=$MEDIAWIKI_PATH/htdocs/extensions
export SKINS_PATH=$MEDIAWIKI_PATH/htdocs/extensions
export LOCAL_SETTINGS_PATH=$MEDIAWIKI_PATH/htdocs/LocalSettings.php

export MANDRILL_PASSWORD=$(cat mandrill_password.txt)

# Install EmbedVideo
wget https://github.com/HydraWiki/mediawiki-embedvideo/archive/v2.7.0.zip
unzip v2.7.0.zip
cp -R mediawiki-embedvideo-2.7.0 $EXTENSION_PATH/EmbedVideo/
grep EmbedVideo $LOCAL_SETTINGS_PATH || echo "wfLoadExtension( 'EmbedVideo' );" >> $LOCAL_SETTINGS_PATH

# Install VisualEditor
wget https://extdist.wmflabs.org/dist/extensions/VisualEditor-REL1_30-61f161a.tar.gz
tar xvzf VisualEditor-REL1_30-61f161a.tar.gz
cp -R VisualEditor $EXTENSION_PATH
grep VisualEditor $LOCAL_SETTINGS_PATH || cat << 'EOF' >> $LOCAL_SETTINGS_PATH
wfLoadExtension( 'VisualEditor' );
$wgDefaultUserOptions['visualeditor-enable'] = 1;
$wgDefaultUserOptions['visualeditor-editor'] = "visualeditor";
$wgHiddenPrefs[] = 'visualeditor-enable';
$wgVirtualRestConfig['modules']['parsoid'] = array(
    // URL to the Parsoid instance
    // Use port 8142 if you use the Debian package
    'url' => 'http://localhost:8142',
    // Parsoid "domain", see below (optional)
    'domain' => 'localhost',
    // Parsoid "prefix", see below (optional)
    'prefix' => 'localhost'
);
EOF

# Install Parsoid
echo "deb https://releases.wikimedia.org/debian jessie-mediawiki main" | sudo tee /etc/apt/sources.list.d/parsoid.list
sudo apt-get install apt-transport-https
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo apt-get update
sudo apt-get install parsoid

# Install Mandrill
sudo pear install mail
sudo pear install net_smtp
grep wgSmtp $LOCAL_SETTINGS_PATH || cat <<EOF >> $LOCAL_SETTINGS_PATH
\$wgSMTP = array(
    'host' => 'smtp.mandrillapp.com',
    'port' => 587,
    'username' => 'self',
    'password' => '$MANDRILL_PASSWORD',
    'auth' => true
);
EOF

# Install InputBox
wget https://extdist.wmflabs.org/dist/extensions/InputBox-REL1_30-38433cd.tar.gz
tar xvzf InputBox-REL1_30-38433cd.tar.gz
cp -R InputBox $EXTENSION_PATH
grep InputBox $LOCAL_SETTINGS_PATH || echo "wfLoadExtension( 'InputBox' );" >> $LOCAL_SETTINGS_PATH

# Install Mobile
wget https://extdist.wmflabs.org/dist/extensions/MobileFrontend-REL1_30-5ecc673.tar.gz
tar xvzf MobileFrontend-REL1_30-5ecc673.tar.gz
cp -R MobileFrontend $EXTENSION_PATH
grep MobileFrontend $LOCAL_SETTINGS_PATH || cat <<'EOF' >> $LOCAL_SETTINGS_PATH
wfLoadExtension( 'MobileFrontend' );
$wgMFAutodetectMobileView = true;
EOF

wget https://extdist.wmflabs.org/dist/skins/MinervaNeue-REL1_30-7ee8663.tar.gz
tar xvzf MinervaNeue-REL1_30-7ee8663.tar.gz
cp -R MinervaNeue $SKINS_PATH
grep MinervaNeue $LOCAL_SETTINGS_PATH || cat <<'EOF' >> $LOCAL_SETTINGS_PATH
wfLoadSkin( 'MinervaNeue' );
$wgMFDefaultSkinClass = 'SkinMinervaNeue';
EOF
