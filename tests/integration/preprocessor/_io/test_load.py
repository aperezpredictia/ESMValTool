"""Integration tests for :func:`esmvaltool.preprocessor._io.concatenate`"""

from __future__ import absolute_import, division, print_function

import os
import tempfile
import unittest

import iris
import numpy as np
from iris.coords import DimCoord
from iris.cube import Cube

from esmvaltool.preprocessor import load
from esmvaltool.preprocessor._io import concatenate_callback


class TestLoad(unittest.TestCase):
    """Tests for :func:`esmvaltool.preprocessor._io.concatenate`"""

    def setUp(self):
        self.temp_files = []

    def tearDown(self):
        for temp_file in self.temp_files:
            os.remove(temp_file)

    def _create_sample_cube(self):
        coord = DimCoord(
            [1, 2], standard_name='latitude', units='degrees_north')
        cube = Cube(
            [1, 2], var_name='sample', dim_coords_and_dims=((coord, 0), ))
        return cube

    def _save_cube(self, cube):
        descriptor, temp_file = tempfile.mkstemp('.nc')
        os.close(descriptor)
        iris.save(cube, temp_file)
        self.temp_files.append(temp_file)

    def test_load_multiple(self):
        """Test loading multiple files"""
        for _ in range(2):
            cube = self._create_sample_cube()
            self._save_cube(cube)

        cubes = load(self.temp_files, None)
        cube = cubes[0]
        self.assertTrue((cube.data == np.array([1, 2])).all())
        self.assertTrue((cube.coord('latitude').points == np.array([1,
                                                                    2])).all())

    def test_callback_remove_attributtes(self):
        """Test callback remove unwanted attributes"""
        attributtes = ('history', 'creation_date', 'tracking_id')
        for _ in range(2):
            cube = self._create_sample_cube()
            for attr in attributtes:
                cube.attributes[attr] = attr
            self._save_cube(cube)

        cubes = load(self.temp_files, None, callback=concatenate_callback)
        cube = cubes[0]
        self.assertTrue((cube.data == np.array([1, 2])).all())
        self.assertTrue((cube.coord('latitude').points == np.array([1,
                                                                    2])).all())
        for attr in attributtes:
            self.assertTrue(attr not in cube.attributes)

    def test_callback_fix_lat_units(self):
        """Test callback for fixing units"""
        cube = self._create_sample_cube()
        self._save_cube(cube)

        cubes = load(self.temp_files, None, callback=concatenate_callback)
        cube = cubes[0]
        self.assertTrue((cube.data == np.array([1, 2])).all())
        self.assertTrue((cube.coord('latitude').points == np.array([1,
                                                                    2])).all())
        self.assertEquals(cube.coord('latitude').units, 'degrees_north')
