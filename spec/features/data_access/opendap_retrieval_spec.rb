require 'spec_helper'

describe 'OPeNDAP Retrieval', reset: false do

  before(:all) do
    load_page :search, overlay: false
    login
  end

  after(:all) do
    wait_for_xhr
    AccessConfiguration.destroy_all if page.server.responsive?
  end

  opendap_dataset = 'C181553784-GSFCS4PA'
  non_opendap_dataset = 'C179003030-ORNL_DAAC'

  context 'configuring a non-OPeNDAP dataset and selecting the "Download" option' do
    before(:all) do
      load_page 'data/configure', project: [non_opendap_dataset]
      choose 'Download'
    end

    it "displays no subsetting options" do
      expect(page).to have_no_text('Spatial subsetting')
      expect(page).to have_no_text('Parameters')
    end

    it "displays no file format conversion options" do
      expect(page).to have_no_text('File format')
      expect(page).to have_no_field('Original (No Subsetting)')
    end
  end

  context 'configuring an OPeNDAP dataset and selecting the "Download" option' do
    before(:all) do
      load_page('data/configure',
                project: [opendap_dataset],
                bounding_box: [0, 0, 2, 2],
                temporal: ['2014-07-23T00:00:00Z', '2014-08-02T00:00:00Z'])
      choose 'Download'
    end

    it "displays a choice of file formats" do
      expect(page).to have_text('File format')
    end

    it "chooses the original format by default" do
      expect(page).to have_checked_field('Original (No Subsetting)')
    end

    context 'choosing the ASCII file format' do
      before(:all) do
        choose 'ASCII'
      end

      it 'shows spatial subsetting options' do
        expect(page).to have_text('Spatial subsetting')
      end

      it 'defaults spatial subsetting options to being checked' do
        expect(page).to have_checked_field("Subset to my spatial search area's bounding box")
      end

      it 'shows a map displaying the spatial subsetting area' do
        expect(page).to have_css('.access-subset-map > .access-mbr[style="top: 86px; left: 178px; height: 6px; width: 6px; "]')
      end

      it 'shows parameter subsetting options' do
        expect(page).to have_text('Parameters')
      end

      it 'defaults parameter subsetting options to being checked' do
        expect(page).to have_checked_field('AbsorbingAerosolOpticalThicknessMW')
        expect(page).to have_checked_field('AerosolModelMW')
      end
    end

    context 'choosing the original file format' do
      before(:all) do
        choose 'Original (No Subsetting)'
      end

      it 'hides spatial subsetting' do
        expect(page).to have_no_text('Spatial subsetting')
        expect(page).to have_no_field("Subset to my spatial search area's bounding box")
      end

      it 'hides parameter subsetting' do
        expect(page).to have_no_text('Parameters')
        expect(page).to have_no_field('AbsorbingAerosolOpticalThicknessMW')
      end
    end
  end

  context 'downloading an OPeNDAP dataset with subsetting options' do
    before(:all) do
      load_page('data/configure',
                project: [opendap_dataset],
                bounding_box: [0, 0, 2, 2],
                temporal: ['2014-07-23T00:00:00Z', '2014-08-02T00:00:00Z'])
      choose 'Download'
      choose 'ASCII'
      uncheck 'AerosolModelMW'
      click_on 'Submit'
      click_link "View Download Links"
    end

    after(:all) do
      Capybara.reset_sessions!
      load_page :search, overlay: false
      login
    end

    it 'provides a URL describing metadata about the dataset\'s parameters' do
      within_window('Earthdata Search - Downloads') do
        expect(page).to have_css('a[href*=".he5.info"]')
      end
    end

    it 'provides links the data in the selected file format' do
      within_window('Earthdata Search - Downloads') do
        expect(page).to have_css('a[href*=".he5.ascii?"]')
        expect(page).to have_css('a[href*="http://acdisc.gsfc.nasa.gov/opendap"]')
        expect(page).to have_no_content('a[href*="ftp://acdisc.gsfc.nasa.gov/data/s4pa/"]')
      end
    end

    it 'subsets the data to the selected parameters' do
      within_window('Earthdata Search - Downloads') do
        expect(page).to have_css('a[href*="AbsorbingAerosolOpticalThicknessMW"]')
        expect(page).to have_css('a[href*="AerosolOpticalThicknessMW"]')
        expect(page).to have_no_css('a[href*="AerosolModelMW"]')
      end
    end

    it 'applies spatial subsetting' do
      within_window('Earthdata Search - Downloads') do
        expect(page).to have_css('a[href*="AbsorbingAerosolOpticalThicknessMW[0:4][360:368][720:728]"]')
        expect(page).to have_css('a[href$="lon[720:728],lat[360:368],nWavelDiagnostic"]')
      end
    end
  end

  context 'downloading an OPeNDAP dataset in its original format' do
    before(:all) do
      load_page('data/configure',
                project: [opendap_dataset],
                bounding_box: [0, 0, 2, 2],
                temporal: ['2014-07-23T00:00:00Z', '2014-08-02T00:00:00Z'])
      choose 'Download'
      choose 'Original (No Subsetting)'
      click_on 'Submit'
      click_link "View Download Links"
    end

    after(:all) do
      Capybara.reset_sessions!
      load_page :search, overlay: false
      login
    end

    it 'does not provide a URL describing the dataset\'s parameters' do
      within_window('Earthdata Search - Downloads') do
        expect(page).to have_no_css('a[href*=".info"]')
      end
    end

    it 'provides links to the original data without opendap parameters' do
      within_window('Earthdata Search - Downloads') do
        expect(page).to have_no_css('a[href*="http://acdisc.gsfc.nasa.gov/opendap"]')
        expect(page).to have_css('a[href*="ftp://acdisc.gsfc.nasa.gov/data/s4pa/"]')
      end
    end
  end
end