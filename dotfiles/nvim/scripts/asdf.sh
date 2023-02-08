rm -rf ~/.asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.9.0
echo $'\n# asdf config' >> ~/.bashrc
echo '. $HOME/.asdf/asdf.sh' >> ~/.bashrc
echo '. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc
. ~/.bashrc

cat .tool-versions | cut -d' ' -f1 | grep "^[^\#]" | xargs -i asdf plugin add  {}
