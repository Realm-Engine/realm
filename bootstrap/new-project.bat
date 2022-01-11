dub add-local .
dub init ./Projects/%1 --non-interactive
cd ./Projects/%1
mkdir .\Assets
mkdir .\Assets\Models
mkdir .\Assets\Images
mkdir .\Assets\Shaders