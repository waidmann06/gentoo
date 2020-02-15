# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: ruby-ng-gnome2.eclass
# @MAINTAINER:
# Ruby herd <ruby@gentoo.org>
# @AUTHOR:
# Author: Hans de Graaff <graaff@gentoo.org>
# @SUPPORTED_EAPIS: 6 7
# @BLURB: An eclass to simplify handling of various ruby-gnome2 parts.
# @DESCRIPTION:
# This eclass simplifies installation of the various pieces of
# ruby-gnome2 since they share a very common installation procedure.

case "${EAPI:-0}" in
	6|7)
		;;
	*)
		die "Unsupported EAPI=${EAPI} (unknown) for ${ECLASS}"
		;;
esac

RUBY_FAKEGEM_NAME="${RUBY_FAKEGEM_NAME:-${PN#ruby-}}"
RUBY_FAKEGEM_TASK_TEST=""
RUBY_FAKEGEM_TASK_DOC=""

# @ECLASS-VARIABLE: RUBY_GNOME2_NEED_VIRTX
# @PRE_INHERIT
# @DESCRIPTION:
# If set to 'yes', the test is run with virtx. Set before inheriting this
# eclass.
: ${RUBY_GNOME2_NEED_VIRTX:="no"}

inherit ruby-fakegem
if [[ ${RUBY_GNOME2_NEED_VIRTX} == yes ]]; then
	inherit virtualx
fi

IUSE="test"
RESTRICT+=" !test? ( test )"

DEPEND="virtual/pkgconfig"
ruby_add_bdepend "
	dev-ruby/pkg-config
	test? ( >=dev-ruby/test-unit-2 )"
RUBY_S=ruby-gnome2-all-${PV}/${RUBY_FAKEGEM_NAME}
SRC_URI="mirror://sourceforge/ruby-gnome2/ruby-gnome2-all-${PV}.tar.gz"
HOMEPAGE="https://ruby-gnome2.osdn.jp/"
LICENSE="LGPL-2.1+"
SLOT="0"

# @FUNCTION: each_ruby_configure
# @DESCRIPTION:
# Run the configure script in the subbinding for each specific ruby target.
each_ruby_configure() {
	${RUBY} extconf.rb || die "extconf.rb failed"
}

# @FUNCTION: each_ruby_compile
# @DESCRIPTION:
# Compile the C bindings in the subbinding for each specific ruby target.
each_ruby_compile() {
	# We have injected --no-undefined in Ruby as a safety precaution
	# against broken ebuilds, but the Ruby-Gnome bindings
	# unfortunately rely on the lazy load of other extensions; see bug
	# #320545.
	find . -name Makefile -print0 | xargs -0 \
		sed -i -e 's:-Wl,--no-undefined ::' \
		-e "s/^ldflags  = /ldflags = $\(LDFLAGS\) /" \
		|| die "--no-undefined removal failed"

	emake V=1 || die "emake failed"
}

# @FUNCTION: each_ruby_install
# @DESCRIPTION:
# Install the files in the subbinding for each specific ruby target.
each_ruby_install() {
	# Create the directories, or the package will create them as files.
	local archdir=$(ruby_rbconfig_value "sitearchdir")
	dodir ${archdir#${EPREFIX}} /usr/$(get_libdir)/pkgconfig

	emake DESTDIR="${D}" install || die "make install failed"

	each_fakegem_install
}

# @FUNCTION: all_ruby_install
# @DESCRIPTION:
# Install the files common to all ruby targets.
all_ruby_install() {
	for doc in ../AUTHORS ../NEWS ChangeLog README; do
		[[ -s ${doc} ]] && dodoc $doc
	done
	if [[ -d sample ]]; then
		insinto /usr/share/doc/${PF}
		doins -r sample || die "sample install failed"
	fi

	all_fakegem_install
}

# @FUNCTION: each_ruby_test
# @DESCRIPTION:
# Run the tests for this package.
each_ruby_test() {
	[[ -e test/run-test.rb ]] || return

	if [[ ${RUBY_GNOME2_NEED_VIRTX} == yes ]]; then
		virtx ${RUBY} test/run-test.rb
	else
		${RUBY} test/run-test.rb || die
	fi
}
