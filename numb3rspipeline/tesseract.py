# -*- coding: utf-8 -*-

import click
import logging
from pathlib import Path

# imports for image processing
import pytesseract
from PIL import Image, ImageEnhance, ImageFilter

# reading and writing files
import sys
import csv
import os

def tesseract(fpath):
    """ Performs the OCR.

    First, it runs the OCR on the original image.
    In a second run, it enhances the image and performs the OCR again.

    :param fpath: the complete image file path
    :return: tuple of two text strings from OCR
    """

    # source partially taken from
    # https://stackoverflow.com/a/37750605

    im = Image.open(fpath)
    # ocr original image
    text_org = pytesseract.image_to_string(im)

    # enchance image
    #im = im.filter(ImageFilter.MedianFilter())
    enhancer = ImageEnhance.Contrast(im)
    im = enhancer.enhance(2)
    #im = im.convert('1')
    #im.save('temp2.jpg')
    # ocr enhanced image
    text_enh = pytesseract.image_to_string(im)

    return text_org, text_enh

def write_txtfile(fpath, url, home_url, text_org, text_enh):
    """ Writes the OCR text into file.

    :param fpath: the complete name of the OCR txt file
    :param url: the url where fpath's file originates from
    :param home_url: website url where the img originates from
    :param text_org: OCR text from the original image
    :param text_org: OCR text from the enhanced image

    :return: tuple of two text strings from OCR
    """

    logger = logging.getLogger(__file__)
    with open(fpath,'w') as txtfile:
        try:
            txtfile.write('##################################\n')
            txtfile.write('Infographic URL: %s\n' % url)
            txtfile.write('Infographic homepage: %s\n' % home_url)
            txtfile.write('Infographic file: %s\n' %  os.path.split(fpath)[1] )
            txtfile.write('##################################\n')
            txtfile.write('\n')
            txtfile.write(text_org.encode('ascii', 'ignore'))
            txtfile.write('\n')
            txtfile.write('##################################\n')
            txtfile.write('\n')
            txtfile.write(text_enh.encode('ascii', 'ignore'))
        except:
            # log error handling
            logger.error('Error writing OCR text on file: %s', fpath)

#############################################
# Main
#############################################
@click.command()
@click.argument('input_dir', type=click.Path(exists=True))
@click.option('-u', '--urlfilelist',
                default='url_filelist.csv',
                help='name of URL file list')
def main(input_dir, urlfilelist):
    logger = logging.getLogger(__file__)
    logger.info('Start OCR in directory: %s', input_dir)

    # parse the url filelist for previously downloaded files
    url_list_filepath = os.path.join(input_dir, urlfilelist)
    if not os.path.exists(url_list_filepath):
        logger.error('Could not find url filelist: %s', url_list_filepath)
        sys.exit(1)

    logger.info('Reading url filelist: %s', urlfilelist)
    with open(url_list_filepath, 'r') as csvfile:
        reader = csv.DictReader(csvfile, delimiter = ';')
        for row in reader:
            filename = row['filename']
            url = row['url'] # image URL
            try:
                home_url = row['home_url'] # website where the img originates from
            except KeyError:
                logger.warn('No home_url attribute found in file: %s', urlfilelist)
                home_url = ''

            # loop for each file
            try:
                ## reading image file and perform OCR
                img_filepath = os.path.join(input_dir, filename)
                if not os.path.exists(img_filepath):
                    logger.error('Could not find image file: %s', img_filepath)
                    continue
                logger.info('Reading image file: %s', filename)
                text_org, text_enh = tesseract(img_filepath)

                ### writing OCR text into file
                file, file_extension = os.path.splitext(img_filepath)
                txt_filepath = file + '.txt' # img_filepath.txt
                txtfile_dir, txtfile_name = os.path.split(txt_filepath)
                logger.info('Writing text file: %s', txtfile_name)
                write_txtfile(txt_filepath, url, home_url, text_org, text_enh)
            except:
                # log error handling
                logger.error('Error performing OCR on file: %s', filename)


#############################################
# Entry
#############################################
if __name__ == '__main__':
    log_fmt = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    logging.basicConfig(level=logging.INFO, format=log_fmt)

    # not used in this stub but often useful for finding various files
    project_dir = Path(__file__).resolve().parents[2]

    main()
